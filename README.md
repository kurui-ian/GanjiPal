# PesaTrack (GanjiTrace)

> **Offline-First M-Pesa Expense Tracker for Android**

PesaTrack is a personal finance Android application built using Flutter, Dart, SQLite, and native Kotlin. It automatically processes M-Pesa confirmation SMS messages to provide real-time tracking of daily spending, cash flow, budgets, and financial habits—completely offline with 100% on-device privacy.

---

## ✨ Features

- **Automated M-Pesa Ingestion:**
  - Background broadcast receiver (`SmsReceiver.kt`) for incoming M-Pesa SMS messages.
  - Device inbox scanner for historical message import.
  - Manual SMS paste fallback with live parse preview.
- **Dedicated Parser Strategy:**
  - Send Money (person-to-person with phone number normalization)
  - Receive Money (classified strictly as Income)
  - PayBill Payments (with merchant name and account reference)
  - Buy Goods & Services / Till Payments
  - Cash Withdrawals (Agent & ATM; fees separated from principal)
  - Cash Deposits (credited without inflating income)
  - Airtime Purchases (for self and other mobile numbers)
  - Reversals & Refunds (linked to original transactions; offsets net spending)
- **Zero Floating-Point Error:**
  - All currency stored in integer minor units (cents).
- **Deterministic Deduplication:**
  - SHA-256 fingerprinting using official M-Pesa references and composite keys.
  - Enforced via SQLite database unique constraints.
- **Strict Financial Semantics:**
  - Distinguishes expenses, income, transfers, withdrawals, deposits, and reversals.
  - Net Cash Flow = Total Money In minus Total Money Out.
- **Budgets & Spending Alerts:**
  - Daily, weekly, monthly, and category-scoped spending limits.
  - Configurable warning thresholds (e.g., 80% usage alerts).
- **Analytics & Trends:**
  - Daily spending timeline.
  - Category breakdown with visual distribution bars.
  - Top counterparties and merchant rankings.
- **Backup & Portability:**
  - RFC 4180 CSV export.
  - Versioned JSON backup and restore with integrity validation.
- **Strict On-Device Privacy:**
  - Zero external servers or remote telemetry.
  - No cloud sync or third-party AI APIs.

---

## 🏗️ Architecture

```
GanjiTrace/
├── android/                             # Android native Kotlin layer
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml          # SMS permissions & receiver declaration
│   │   └── kotlin/com/pesatrack/app/
│   │       ├── MainActivity.kt          # MethodChannel bridge
│   │       └── SmsReceiver.kt           # Broadcast receiver for M-Pesa SMS
├── packages/pesatrack_core/             # Pure Dart domain engine (100% Unit Tested)
│   ├── lib/
│   │   ├── calculations/                # Cash flow, net spending, budget bounds
│   │   ├── classification/              # Merchant intelligence & categorization
│   │   ├── deduplication/               # Deterministic SHA-256 fingerprinting
│   │   ├── models/                      # Transaction, Category, Budget models
│   │   ├── parser/                      # Strategy pattern SMS parsers
│   │   └── storage/                     # CSV & JSON backup codecs
│   └── test/                            # 29 automated tests
├── lib/                                 # Flutter Material 3 application
│   ├── core/theme/                      # Light & Dark theme definitions
│   ├── data/datasources/                # SQLite database helper & migrations
│   ├── data/repositories/               # Transaction, Category, Budget, SMS repos
│   ├── presentation/providers/          # Reactive AppState
│   └── presentation/screens/            # Dashboard, Transactions, Analytics, Budgets, Settings
└── pubspec.yaml
```

---

## 🧪 Testing

The domain logic, parsers, and financial calculators are covered by an automated test suite:

```powershell
cd packages/pesatrack_core
dart test
```

All 29 tests pass with 100% success rate across all M-Pesa SMS fixtures.

---

## 🚀 Building the APK

```powershell
# Get dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

Outputs:
- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`
