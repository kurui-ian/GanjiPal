# M-Pesa SMS Parsing Specification

This document outlines the grammar, regex structures, and classification rules implemented in the pure-Dart `pesatrack_core` parser engine.

---

## 📩 Supported Transaction Archetypes

| Type | Strategy Class | Sample Keyword / Signature |
| :--- | :--- | :--- |
| **PayBill** | `PayBillStrategy` | `sent to ... for account ...` |
| **Buy Goods** | `BuyGoodsStrategy` | `paid to ...` |
| **Send Money** | `SendMoneyStrategy` | `sent to [Name] [Phone]` |
| **Receive Money** | `ReceiveMoneyStrategy` | `received Ksh... from ...` |
| **Agent Withdrawal** | `WithdrawAgentStrategy` | `Withdraw Ksh... from [Agent]` |
| **ATM Withdrawal** | `WithdrawAtmStrategy` | `Withdraw Ksh... from ATM` |
| **Cash Deposit** | `DepositStrategy` | `Give Ksh... to [Agent]` |
| **Airtime Purchase** | `AirtimeStrategy` | `bought Ksh... of airtime for ...` |
| **Transaction Reversal**| `ReversalStrategy` | `Reversal of transaction [REF]` |

---

## 🔍 Canonical Regex Patterns

### 1. PayBill Parsing Pattern
```regex
^([A-Z0-9]+)\s+Confirmed\.\s+Ksh([0-9,]+(?:\.[0-9]{2})?)\s+sent\s+to\s+(.+?)\s+for\s+account\s+(.+?)\s+on\s+(\d{1,2}/\d{1,2}/\d{2,4})\s+at\s+(\d{1,2}:\d{2}\s*(?:AM|PM))\.\s*(?:New\s+M-PESA\s+balance\s+is\s+Ksh([0-9,]+(?:\.[0-9]{2})?)\.)?\s*(?:Transaction\s+cost,\s+Ksh([0-9,]+(?:\.[0-9]{2})?)\.)?
```

### 2. Buy Goods Parsing Pattern
```regex
^([A-Z0-9]+)\s+Confirmed\.\s+Ksh([0-9,]+(?:\.[0-9]{2})?)\s+paid\s+to\s+(.+?)\.\s+on\s+(\d{1,2}/\d{1,2}/\d{2,4})\s+at\s+(\d{1,2}:\d{2}\s*(?:AM|PM))\.\s*(?:New\s+M-PESA\s+balance\s+is\s+Ksh([0-9,]+(?:\.[0-9]{2})?)\.)?\s*(?:Transaction\s+cost,\s+Ksh([0-9,]+(?:\.[0-9]{2})?)\.)?
```

---

## 🛡️ Edge Cases & Sanitization

1. **Amount Normalization**: Strips thousands comma separators (`1,250.00` -> `125000 cents`).
2. **Fuliza Support**: Overdraft notifications embedded within the SMS are parsed without altering base transaction costs.
3. **Reversal Matching**: Reversal messages automatically set `review_status = flagged` on the original transaction if matching reference is stored in SQLite.
