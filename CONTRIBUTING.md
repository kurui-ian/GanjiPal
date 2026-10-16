# Contributing to PesaTrack (GanjiTrace)

Thank you for your interest in contributing to PesaTrack! This guide outlines the development workflow, coding standards, and procedures for submitting improvements, bug fixes, and new features.

---

## 🛠️ Prerequisites

Before you start, make sure you have the following installed:
- **Flutter SDK:** Version `3.24.x` or newer (stable channel)
- **Dart SDK:** Version `3.5.x` or newer
- **Android SDK:** Platforms API 34 through 36
- **Java Development Kit (JDK):** Version 17 (recommended: Eclipse Temurin or OpenJDK)
- **Git**

---

## 🚀 Local Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kurui-ian/GanjiTrace.git
   cd GanjiTrace
   ```

2. **Install root Flutter project dependencies:**
   ```bash
   flutter pub get
   ```

3. **Install core domain package dependencies:**
   ```bash
   cd packages/pesatrack_core
   dart pub get
   cd ../..
   ```

4. **Verify your Flutter toolchain:**
   ```bash
   flutter doctor
   ```

---

## 🧪 Running Automated Tests

PesaTrack maintains high test coverage across both domain parsing logic and Flutter UI presentation:

### 1. Pure Dart Domain Tests (`pesatrack_core`)
```bash
cd packages/pesatrack_core
dart test
cd ../..
```

### 2. Flutter Widget & Unit Tests
```bash
flutter test
```

---

## 🧹 Code Quality & Linting

Before opening a pull request, ensure all code conforms to project standards:

1. **Run Flutter static analysis:**
   ```bash
   flutter analyze
   ```
   > All changes must pass with `No issues found!`.

2. **Format Dart code:**
   ```bash
   dart format .
   ```

---

## 📝 Commit Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat(scope): ...` — A new feature
- `fix(scope): ...` — A bug fix
- `docs(scope): ...` — Documentation updates
- `test(scope): ...` — Adding or refactoring tests
- `refactor(scope): ...` — Code changes that neither fix bugs nor add features
- `chore(scope): ...` — Maintenance, toolchain, or dependency updates

---

## 🔀 Pull Request Process

1. Fork the repository and create your feature branch from `main`:
   ```bash
   git checkout -b feat/my-new-feature
   ```
2. Commit your changes with clear, descriptive commit messages.
3. Verify that all tests pass (`dart test` and `flutter test`).
4. Push to your fork and submit a Pull Request to `main`.
5. Ensure all automated GitHub Actions CI checks pass.
