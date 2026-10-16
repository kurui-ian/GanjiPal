# PesaTrack Privacy Manifesto & Security Model

> **Core Commitment:** PesaTrack (GanjiTrace) is built from the ground up on the principle of **absolute on-device financial privacy**. Your money, receipts, and spending patterns belong solely to you.

---

## 🛡️ The 7 Privacy Pillars

### 1. No Internet Permission
PesaTrack **does not declare** the `android.permission.INTERNET` privilege in its `AndroidManifest.xml`. It is physically impossible for the application to transmit your financial records, SMS receipts, or balances over the network.

### 2. 100% On-Device Processing
All parsing, categorization, deduplication, and budget calculations run locally on your phone's processor using the embedded Dart domain engine (`pesatrack_core`). No cloud APIs or external AI servers are ever invoked.

### 3. Selective SMS Access
- **Inbox Scanning:** PesaTrack only parses messages sent from official Safaricom sender identifiers (`MPESA` or containing standard M-Pesa confirmation phrases).
- **Zero Personal Message Retention:** Personal text messages from contacts, family, or friends are strictly ignored and never stored or logged.

### 4. Application-Private Storage
Financial transactions and audit logs are persisted exclusively within the app-private SQLite database sandbox (`/data/user/0/com.pesatrack.app/databases/pesatrack.db`). Other applications on the Android device cannot read this database.

### 5. Deterministic Non-Reversible Hashing
For duplicate detection and audit records, SMS messages are hashed using cryptographic SHA-256 (`DeduplicationService.hashRawSms`). Raw, unparsed text strings from incoming broadcast messages are not stored.

### 6. User-Controlled Exports
Backup files (JSON) and spreadsheets (CSV) are generated only when explicitly initiated by the user from the Settings screen. The generated files are handled via Android's native system file picker or system share sheet, putting you in complete control over where they are saved.

### 7. Zero Telemetry & Zero Advertisements
- No Google Firebase Analytics
- No Crashlytics
- No Facebook SDK
- No advertising SDKs
- No user tracking or behavioral telemetry

---

## 🔍 Verification for Developers & Auditors

You can verify these security claims independently in the open-source codebase:
- Check `android/app/src/main/AndroidManifest.xml`: Verify that `<uses-permission android:name="android.permission.INTERNET" />` is absent.
- Check `pubspec.yaml`: Verify that no networking libraries (`http`, `dio`) or telemetry packages are bundled in production dependencies.
- Inspect `packages/pesatrack_core`: Verify that all domain logic operates on in-memory models without network calls.
