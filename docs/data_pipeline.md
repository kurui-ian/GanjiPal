# GanjiPal Data Processing & Ingestion Pipeline

This document details the lifecycle of financial data in GanjiPal—from raw incoming SMS triggers to presentation in reactive UI widgets.

---

## 🔄 End-to-End Ingestion Flow

```mermaid
sequenceDiagram
    autonumber
    actor Mpesa as Safaricom M-Pesa
    participant Android as Android Telephony (SMS)
    participant Receiver as SmsReceiver / Channel
    participant Core as pesatrack_core Engine
    participant DB as SQLite Storage (pesatrack.db)
    participant AppState as AppState Provider
    actor User as User UI

    Mpesa->>Android: Sends Transaction SMS
    Android->>Receiver: Broadcast (SMS_RECEIVED)
    Receiver->>Core: Forward raw text & sender
    Core->>Core: Regex match against Strategy Patterns
    Core->>Core: Deduplication hash (SHA-256)
    Core->>DB: Transactional insert (IGNORE on conflict)
    DB-->>AppState: Invalidate memoization caches
    AppState->>AppState: Recalculate daily/weekly/monthly summaries
    AppState->>User: NotifyListeners -> Re-render 120fps UI
```

---

## 🧮 Monetary Precision & Integrity

1. **Integer Minor Units**:
   - All amounts are stored as integer cents (`amountCents`, `feeCents`).
   - Formula: `KSh 1,450.50` -> `145050 cents`.
   - Prevents IEEE 754 floating-point rounding errors during financial aggregation.

2. **Deterministic Deduplication**:
   - Official M-Pesa transactions use reference hashes: `SHA-256("REF:" + mpesaReference)`.
   - Reversal transactions are tagged and link back to original transactions via `reversal_reference`.

3. **Performance & Memoization**:
   - Dashboard aggregations use memoized caches (`_cachedTodaySummary`, `_cachedWeekSummary`, `_cachedMonthSummary`).
   - Cache invalidation occurs automatically on database mutation (`addTransaction`, `editTransaction`, `deleteTransaction`).
