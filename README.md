# Khmer PDF Shaper

A pure Dart package for rendering complex Khmer Unicode text correctly in PDF documents (`package:pdf`), featuring OpenType GSUB shaping, mixed-script layout, cluster-safe wrapping, TrueType glyph subsetting, and searchable/copyable `ToUnicode` PDF embedding.

---

## 🎯 What Problem This Solves

Khmer is an Indic-derived Brahmic script with complex rendering rules:
- Subscript consonants (*Coeng* / ជើង) reorder or transform into distinct below-base/post-base glyph forms.
- Pre-base vowels (e.g. `U+17C1` េ) must reorder visually to the left of base consonants.
- Multi-part split vowels (e.g. `U+17C4` ោ) decompose into separate pre-base and post-base glyphs.
- Above/below marks stack and reposition dynamically.

Standard PDF generators like `package:pdf` lack an OpenType shaping engine. Passing raw Khmer Unicode to `pw.Text` results in broken glyph sequences, missing subscripts, un-reordered vowels, and illegible text.

`khmer_pdf_shaper` solves this completely in pure Dart with **zero external native dependencies** (no `harfbuzz_ffi`, no `dart:ffi`, no `dart:io` in runtime code paths).

---

## 🚀 Quick Start

Add `khmer_pdf_shaper` and `pdf` to your `pubspec.yaml`:

```yaml
dependencies:
  pdf: ^3.11.3
  khmer_pdf_shaper: ^1.0.0
```

Use `KhmerText` directly in place of `pw.Text`:

```dart
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> generatePdf() async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Center(
        child: KhmerText(
          'សួស្តី ពិភពលោក',
          style: const pw.TextStyle(
            fontSize: 24,
            color: PdfColors.indigo900,
          ),
        ),
      ),
    ),
  );

  return await pdf.save();
}
```

No async font loaders, no asset initialization, and no manual font setup required. The bundled **Battambang-Regular** font is automatically configured and embedded.

---

## 💡 Features & Usage

### 1. Mixed Khmer + Latin / Numeric Text

`KhmerText` automatically segments mixed text runs into Khmer and Latin/numeric clusters, measuring each with proper font metrics and aligning them along a unified baseline:

```dart
KhmerText(
  'Invoice សួស្តី 123 — Price: \$10.50 កម្ពុជា',
  style: pw.TextStyle(
    fontSize: 14,
    font: pw.Font.helveticaBold(), // Custom font for Latin/digits
  ),
)
```

> **Note on `pw.TextStyle.font`:** `style.font` sets the font for non-Khmer runs (Latin letters, numbers, punctuation). Khmer runs always use the bundled Battambang font in v1.

### 2. Cluster-Safe Multi-Line Wrapping

Khmer words are traditionally written without spaces. `KhmerText` implements cluster-safe line breaking:
- **Preferred break points:** Space (`U+0020`), Zero-Width Space (`U+200B`), and explicit newlines (`\n`).
- **Fallback break points:** Safely breaks between shaping clusters when text exceeds container width.
- **Integrity guarantee:** Never breaks inside a complex consonant-vowel-subscript cluster.

```dart
pw.Container(
  width: 250,
  child: KhmerText(
    'ភាសាខ្មែរ គឺជាភាសាផ្លូវការរបស់ប្រទេសកម្ពុជា '
    'ហើយត្រូវបានប្រើប្រាស់ដោយប្រជាជនខ្មែរទូទាំងពិភពលោក។',
    style: const pw.TextStyle(fontSize: 12),
    lineHeightFactor: 1.5,
  ),
)
```

### 3. Text Alignment

Supports standard horizontal text alignments:

```dart
KhmerText('សួស្តី Left', textAlign: pw.TextAlign.left)
KhmerText('សួស្តី Center', textAlign: pw.TextAlign.center)
KhmerText('សួស្តី Right', textAlign: pw.TextAlign.right)
```

### 4. MultiPage Document Support

`KhmerText` works seamlessly inside `pw.MultiPage` documents (headers, paragraphs, tables, lists):

```dart
pdf.addPage(
  pw.MultiPage(
    build: (context) => [
      pw.Header(level: 0, text: 'Document Title'),
      KhmerText('កថាខណ្ឌទីមួយ នៃឯកសារផ្លូវការ', style: const pw.TextStyle(fontSize: 14)),
      pw.SizedBox(height: 10),
      KhmerText('កថាខណ្ឌទីពីរ នៃឯកសារផ្លូវការ', style: const pw.TextStyle(fontSize: 14)),
    ],
  ),
);
```

---

## 🌐 Platform Compatibility

| Platform | Supported | Notes |
| :--- | :---: | :--- |
| **Flutter Mobile (iOS & Android)** | ✅ | Zero configuration |
| **Flutter Desktop (macOS, Windows, Linux)** | ✅ | Zero configuration |
| **Flutter Web** | ✅ | Pure Dart (no `dart:io` or `dart:ffi` runtime dependencies) |
| **Dart CLI / Server Backend** | ✅ | Standalone PDF generation without Flutter engine |

---

## 📊 Feature Parity vs `pw.Text`

| Feature | `pw.Text` | `KhmerText` (v1) | Notes |
| :--- | :---: | :---: | :--- |
| `fontSize` | ✅ | ✅ | Fully supported (must be > 0) |
| `color` | ✅ | ✅ | Fill color applied to all runs |
| `font` (Latin / Numbers) | ✅ | ✅ | Configurable via `pw.TextStyle.font` |
| `font` (Khmer) | ❌ | ✅ | Bundled Battambang-Regular automatically embedded |
| `textAlign` (`left`, `center`, `right`) | ✅ | ✅ | Fully supported |
| `textAlign` (`justify`) | ✅ | ⚠️ | Falls back to left alignment in v1 |
| Cluster-safe wrapping | ❌ | ✅ | Wraps at Space, ZWSP, or cluster boundaries |
| Explicit newlines (`\n`) | ✅ | ✅ | Preserved and split correctly |
| Mixed Khmer / Latin / Numbers | ❌ | ✅ | Automatic segmentation & baseline alignment |
| MultiPage container | ✅ | ✅ | Renders inside `pw.MultiPage` |
| Page spanning (`SpanningWidget`) | ✅ | ❌ | Single widget instance does not break across page boundaries |
| Searchable & Copyable PDF text | ❌ (broken) | ✅ | Complete `ToUnicode` CMap & CID mapping |

---

## 🔍 Why `pw.Text` Alone Fails for Khmer

When rendering `សួស្តី` (`U+179F U+17BD U+179F U+17D2 U+178F U+17B8`):
1. **Unshaped Subscripts:** `U+17D2` (Coeng) + `U+178F` (Ta) must be substituted with the subscript *Coeng Ta* glyph. `pw.Text` renders them as raw, disconnected characters.
2. **Missing Mark Positioning:** Above vowels (e.g. `U+17B8` ី) and below marks must attach to the cluster base.
3. **Missing PDF ToUnicode CMap:** Even if unshaped glyphs appear, PDF viewers cannot search or copy the original Unicode text without a conforming `ToUnicode` map.

`khmer_pdf_shaper` resolves all three by computing glyph indices via OpenType GSUB tables, calculating cluster advance metrics, and generating proper CID-keyed subsetted TrueType font structures.

---

## ⚠️ Scope & Limitations (v1.0.0)

- **Bundled Font Contract:** v1 is strictly bound to the bundled `Battambang-Regular.ttf` font. Arbitrary custom Khmer fonts are not supported in v1.
- **Font Selection Semantics:** `style.font` applies to non-Khmer text runs only (Latin, numbers, punctuation); it does not alter the Khmer shaping font.
- **Text Direction:** Only Left-to-Right (LTR) reading direction is supported. Bidirectional (bidi) and Right-to-Left (RTL) text are not supported.
- **Layout & Typography:** No text justification (`textAlign: justify` falls back to left alignment), no rich inline spans (`pw.RichText`), and no `maxLines`/`overflow: ellipsis`.
- **Word Segmentation:** Cluster-safe wrapping breaks between legal layout units (`SPACE`, `NBSP`, `ZWSP`) or between valid shaping clusters when unspaced. It does not perform dictionary-based Khmer word segmentation.
- **Cross-Page Spanning:** A single `KhmerText` widget instance renders within its box constraints and does not break across page boundaries. In `pw.MultiPage` documents, structure long content across separate paragraph widgets.
- **Unsupported Characters:** Unsupported non-Khmer characters (e.g. emojis, Cyrillic, Arabic) deterministically fall back to `'?'` under the default Latin Type1 font. For non-Latin scripts, supply a Unicode-capable `PdfFont` in `style.font`.

---

## 📜 Licensing & Attribution

- **Software**: `khmer_pdf_shaper` is released under the [MIT License](LICENSE).
- **Battambang Font**: Bundled `Battambang-Regular.ttf` is licensed under the [SIL Open Font License, Version 1.1](THIRD_PARTY_NOTICES.md) (Copyright 2019 The Battambang Khmer Project Authors, designed by Danh Hong). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for full license terms.
