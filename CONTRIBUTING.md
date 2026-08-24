# Contributing to Khmer PDF Shaper

Thank you for your interest in contributing to `khmer_pdf_shaper`!

## Development Setup

1. Clone the repository and install Flutter dependencies:
   ```bash
   git clone https://github.com/hengmengsroin/khmer_pdf_shaper.git
   cd khmer_pdf_shaper
   flutter pub get
   (cd example && flutter pub get)
   ```

2. Run the test suite:
   ```bash
   flutter test
   ```

3. Run the complete release verification suite:
   ```bash
   ./tool/release_check.sh
   ```

---

## Golden Fixtures Policy

- **Immutable Golden Fixtures**: The 206 fixtures in `test/fixtures/khmer_golden_fixtures.json` are frozen reference baselines.
- **No Auto-Updating**: Unit tests never update or overwrite fixtures automatically.
- **HarfBuzz Differential Procedure**: If a golden test fails, follow the strict 6-step review procedure documented in [`doc/golden_testing.md`](doc/golden_testing.md).

---

## Code Quality & PR Guidelines

Before submitting a Pull Request:
1. Ensure `flutter analyze` reports zero issues.
2. Format code using `dart format .`.
3. Verify that `./tool/release_check.sh` passes all release gates (Gates A–H).
4. Maintain pure Dart portability: do not introduce `dart:ffi` or `dart:io` into runtime package code (`lib/`).
