# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project follows [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-08-24

### Added
* Pure Dart complex text shaping engine for Khmer Unicode script.
* Full OpenType GSUB layout engine with Type 1 (Single), Type 4 (Ligature), and Type 6 (Chaining Context) substitution support.
* Syllable decomposition, cluster classification, and reordering matching the HarfBuzz Khmer shaping model.
* Broken-cluster handling with dotted circle (`U+25CC`) insertion.
* Mixed Khmer and Latin / numeric run segmentation and dynamic baseline alignment.
* Cluster-safe multi-line wrapping supporting Space (`U+0020`), Zero-Width Space (`U+200B`), and fallback cluster boundaries.
* PDF CID/GID encoding, TrueType glyph subsetting, and `ToUnicode` CMap generation for fully searchable and copyable PDF output.
* Zero-configuration `KhmerText` PDF widget with bundled Battambang-Regular font.
* Seamless cross-platform support: Flutter Mobile (iOS/Android), Flutter Desktop (macOS/Windows/Linux), Flutter Web, and Dart CLI.