# Generated Artifacts & Version Control Policy

This document defines repository tracking rules for test artifacts, golden files, and build outputs in `khmer_pdf_shaper`.

## 1. Classification Matrix

| Category | Policy | Path(s) | Description |
| :--- | :--- | :--- | :--- |
| **COMMITTED** | Tracked in Git | `test/fixtures/khmer_golden_fixtures.json` | 206 frozen golden fixtures with HarfBuzz reference metrics |
| **COMMITTED** | Tracked in Git | `test/fixtures/khmer_preprocessing_fixtures.json` | 206 syllable preprocessing decomposition traces |
| **COMMITTED** | Tracked in Git | `test/fixtures/khmer_stress_corpus.json` | 805 generated differential stress cases |
| **COMMITTED** | Tracked in Git | `assets/fonts/Battambang-Regular.ttf` | Exact frozen Battambang font binary (SHA-256 verified) |
| **GENERATED** | Ignored / Ephemeral | `build/` | PDF documents, subset TTF files (`build/subset_test.ttf`), visual golden PDFs |
| **GENERATED** | Ignored / Ephemeral | `.dart_tool/` | Dart build artifacts, CLI test outputs (`.dart_tool/cli_output/`) |
| **GENERATED** | Ignored / Ephemeral | `example/build/` | Flutter web release build output |

---

## 2. Invariants

1. **No Large Binary Blobs**: Generated test PDFs, rasterized PNGs, and temporary font subsets are written to `build/` or `.dart_tool/` and are excluded via `.gitignore`.
2. **Clean Repository State**: Running the release verification suite (`tool/release_check.sh`) must not leave any tracked files dirty in `git status --short`.
3. **Regeneration Commands**:
   - Regenerate all test PDF & TTF artifacts:
     ```bash
     flutter test test/pdf/pdf_visual_fixture_test.dart test/robustness/composite_glyph_stress_test.dart test/robustness/visual_regression_stress_test.dart
     ```
   - Regenerate golden JSON fixtures:
     ```bash
     python3 tool/generate_fixtures.py
     ```
