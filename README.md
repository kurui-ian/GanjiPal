# PesaTrack (GanjiTrace)

> **Offline-First M-Pesa Personal Expense Tracker for Android**

[![Continuous Integration](https://github.com/kurui-ian/GanjiTrace/actions/workflows/ci.yml/badge.svg)](https://github.com/kurui-ian/GanjiTrace/actions/workflows/ci.yml)
[![Build Android APK](https://github.com/kurui-ian/GanjiTrace/actions/workflows/build_apk.yml/badge.svg)](https://github.com/kurui-ian/GanjiTrace/actions/workflows/build_apk.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Privacy: 100% Offline](https://img.shields.io/badge/Privacy-100%25%20On--Device-brightgreen)](docs/PRIVACY.md)

PesaTrack is a personal finance Android application built using Flutter, Dart, SQLite, and native Kotlin. It automatically processes M-Pesa confirmation SMS receipts to provide real-time tracking of daily spending, cash flow, budgets, and financial habits—completely offline with 100% on-device privacy.

---

## ✨ Features

- **Automated M-Pesa Ingestion:**
  - Background broadcast receiver (`SmsReceiver.kt`) for real-time incoming M-Pesa SMS messages.
  - Device inbox scanner for historical message import.
  - Manual SMS paste fallback with live parse preview.
  - **Quick Sample Data Seeder:** One-tap action in Settings to populate realistic demo transactions.
- **Dedicated Parser Strategy:**
  - Send Money (person-to-person with phone number normalization)
  - Receive Money (classified strictly as Income)
  - PayBill Payments (with merchant name and account reference)
  - Buy Goods & Services / Till Payments
  - Cash Withdrawals (Agent & ATM; fees separated from principal)
  - Cash Deposits (credited without inflating income)
  - Airtime Purchases (for self and other mobile numbers)
  - Reversals & Refunds (linked to original transactions; offsets net spending)
  - Pochi la Biashara support
- **Zero Floating-Point Error:**
  - All currency stored in integer minor units (cents: `100 cents = 1 KES`).
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
  - Daily spending timeline and trend charts.
  - Category breakdown with visual distribution bars.
  - Top counterparties and merchant rankings.
- **Backup & Portability:**
  - RFC 4180 CSV export with ISO-8601 timestamps and formula injection defense.
  - Versioned JSON backup and restore with cryptographic integrity validation.
- **Strict On-Device Privacy:**
  - Zero internet permission (`android.permission.INTERNET` is omitted).
  - Zero external servers, cloud AI APIs, or telemetry SDKs.

---

## 🏗️ Architecture & Documentation

For detailed guides, please see:
- 📘 [**Architecture Overview**](docs/ARCHITECTURE.md) — Layered design, domain engine, SQLite schema, and native Android bridges.
- 🛡️ [**Privacy Manifesto**](docs/PRIVACY.md) — Security guarantees and on-device data safety model.
- 🤝 [**Contributing Guide**](CONTRIBUTING.md) — Development setup, test guidelines, and PR procedures.

```
GanjiTrace/
├── .github/workflows/                   # Automated CI & APK build workflows
├── android/                             # Android native Kotlin layer
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml          # SMS permissions & receiver declaration
│   │   └── kotlin/com/pesatrack/app/
│   │       ├── MainActivity.kt          # Telephony ContentProvider & MethodChannel
│   │       └── SmsReceiver.kt           # Broadcast receiver for incoming M-Pesa SMS
├── docs/                                # Architecture & Privacy specifications
├── packages/pesatrack_core/             # Pure Dart domain engine (100% Unit Tested)
│   ├── lib/
│   │   ├── calculations/                # Cash flow, net spending, budget bounds
│   │   ├── classification/              # Merchant intelligence & categorization
│   │   ├── deduplication/               # Deterministic SHA-256 fingerprinting
│   │   ├── models/                      # Transaction, Category, Budget models
│   │   ├── parser/                      # Strategy pattern SMS parsers
│   │   └── storage/                     # RFC 4180 CSV & JSON backup codecs
│   └── test/                            # 33 automated unit tests
├── lib/                                 # Flutter Material 3 application
│   ├── core/theme/                      # Light & Dark theme definitions
│   ├── core/utils/                      # Sample data seeder
│   ├── data/datasources/                # SQLite database helper & migrations
│   ├── data/repositories/               # Transaction, Category, Budget, SMS repos
│   ├── presentation/providers/          # Reactive AppState
│   ├── presentation/screens/            # Dashboard, Transactions, Analytics, Budgets, Settings
│   └── presentation/widgets/            # Reusable UI components
├── test/                                # Flutter widget & interaction tests
└── pubspec.yaml
```

---

## 🧪 Testing

PesaTrack maintains thorough test suites:

### Domain Engine Tests
```powershell
cd packages/pesatrack_core
dart test
```

### Flutter Widget Tests
```powershell
flutter test
```

All tests execute with a 100% pass rate.

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
