# GanjiPal Testing & Verification Guide

This document describes the testing strategy, test suites, and hardware verification procedures for **GanjiPal**.

---

## 🧪 Test Suite Hierarchy

| Scope | Location | Framework | Focus |
| :--- | :--- | :--- | :--- |
| **Domain Logic** | `packages/pesatrack_core/test/` | Pure `dart test` | M-Pesa regex, integer math, deduplication |
| **Data Models** | `packages/pesatrack_core/test/` | Pure `dart test` | Serialization, copyWith, minor units |
| **Widget Tests** | `test/presentation/widgets/` | `flutter_test` | Overflow prevention, theme contrast, taps |
| **Hardware Tests** | Physical Android via ADB | `flutter run -d <device>` | Real-time SMS broadcast and 120Hz refresh |

---

## 🏃 Running Tests Locally

### 1. Pure Dart Domain Tests (Ultra Fast)
```bash
cd packages/pesatrack_core
dart test
```

### 2. Full Flutter Widget Suite
```bash
flutter test
```

### 3. Generate HTML Coverage Report
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 📱 Hardware Testing on Real Devices

To run directly on an attached physical phone (e.g. Samsung Galaxy A25 5G):
```powershell
# 1. Verify ADB detection
adb devices -l

# 2. Launch on device with hot reload
flutter run -d <DEVICE_ID>
```
