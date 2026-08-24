# Release Checklist for v1.0.0

Use this checklist before publishing `khmer_pdf_shaper` to pub.dev:

- [x] **1. Clean Working Tree**: `git status --short` shows no untracked or uncommitted changes.
- [x] **2. Semantic Versioning**: `pubspec.yaml` has version set to `1.0.0`.
- [x] **3. Release Gate Suite**: `./tool/release_check.sh` executes all 8 gates (Gates A–H) and passes with exit code 0.
- [x] **4. Static Analysis**: `flutter analyze` reports zero issues.
- [x] **5. Code Formatting**: `dart format --output=none --set-exit-if-changed .` passes cleanly.
- [x] **6. API Documentation**: `dart doc` generates clean, complete documentation with no missing dartdoc warnings.
- [x] **7. README & Examples**: `README.md` clearly documents quickstart, supported features, limitations, and `example/` runs cleanly.
- [x] **8. Licensing & Attribution**: `LICENSE` (MIT) and `THIRD_PARTY_NOTICES.md` (SIL Open Font License for Battambang) are present.
- [x] **9. CHANGELOG**: `CHANGELOG.md` documents initial v1.0.0 release highlights.
- [x] **10. Pub Publish Dry-Run**: `dart pub publish --dry-run` reports 0 errors and 0 warnings.
- [ ] **11. Publish Approval**: Formal developer authorization before running `dart pub publish`.
- [ ] **12. Git Release Tag**: Create and push tag `v1.0.0` after publication.
