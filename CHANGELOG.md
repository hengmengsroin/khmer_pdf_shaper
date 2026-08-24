# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project follows [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-08-24

### Added
* Initial stable release of `khmer_pdf_shaper`.
* Zero-configuration `KhmerText` widget for `package:pdf` with bundled `Battambang-Regular.ttf` font.
* Pure Dart OpenType GSUB complex text shaping engine supporting Khmer syllable reordering, subscripts (*Coeng* / ជើង), split matras, and above/below mark positioning.
* Differential shaping verified with 100% exact parity against HarfBuzz 14.2.1 across all 206 golden fixtures and 805 stress cases.
* Document-scoped CID/ToUnicode PDF encoding with TrueType glyph subsetting, ensuring fully searchable, copyable, and extractable PDF text.
* Semantic text extraction verified with 100% exact character equality on Apple macOS PDFKit.
* Mixed Khmer and Latin / numeric text segmentation with unified baseline metric alignment.
* Cluster-safe multi-line text wrapping with support for `SPACE`, `NBSP`, `ZWSP`, and explicit newlines (`\n`).
* Pure Dart cross-platform compatibility: Flutter (iOS, Android, macOS, Windows, Linux, Web) and standalone Dart VM / CLI server backends.