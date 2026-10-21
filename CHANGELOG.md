# Changelog

All notable changes to **GanjiPal** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0+1] - 2026-10-21

### Added
- **Animated Splash Screen**: Launch experience with staggered brand text and glowing emerald aura.
- **Animated Amount Counter**: Animated odometer roll effect for smooth financial balance and summary transitions.
- **Universal Screen Compatibility**:
  - FittedBox, SingleChildScrollView, and adaptive LayoutBuilder sizing.
  - Zero `RenderFlex overflow` across all viewport sizes (320px–430px+).
- **Web Platform Support**:
  - Full browser support with `sqflite_common_ffi_web`.
  - PWA Web Manifest and responsive layouts.
- **Physical Device & ADB Toolchain**:
  - Lightweight automated setup for physical Android devices over USB debugging.
  - Portable OpenJDK 17 configuration.

### Performance
- **Memoization Caching**: Added sub-millisecond calculation caches in `AppState` for 60/120 FPS UI rendering.
- **Database Indexing**: Optimized SQLite indexes on `timestamp`, `category_id`, and `classification`.

### Documentation
- Added high-level system architecture and sequence diagrams (`docs/ARCHITECTURE.md`, `docs/data_pipeline.md`).
- Added formal M-Pesa SMS grammar and regex specification (`docs/SMS_PARSING_SPEC.md`).
