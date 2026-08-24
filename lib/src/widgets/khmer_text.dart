import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../layout/khmer_layout_model.dart';
import '../layout/khmer_line_breaker.dart';
import '../pdf/khmer_font_cache.dart';
import '../pdf/khmer_pdf_font.dart';
import '../shaper/battambang_shaper.dart';

/// A `package:pdf` widget that lays out and renders correctly shaped Khmer,
/// Latin, and mixed-script text in PDF documents.
///
/// ### Font Contract & Shaping
/// Khmer text runs are shaped using the bundled `Battambang-Regular.ttf`
/// OpenType shaping engine and embedded with document-scoped CID/ToUnicode
/// structures ensuring visual rendering fidelity, copy-paste extraction,
/// and PDF searchability.
///
/// Non-Khmer text runs (Latin, numbers, symbols) are rendered using [pw.TextStyle.font]
/// when supplied by the caller, or the default `package:pdf` Latin font (Helvetica).
/// Note: `style.font` does NOT replace the Khmer shaping font in v1.
///
/// ### Line Breaking & Layout
/// Text wraps at natural space boundaries (`SPACE`, `NBSP`, `ZWSP`) and falls back
/// to cluster-safe boundaries. The layout engine guarantees that line breaks
/// NEVER occur inside a complex shaping syllable cluster.
///
/// ### MultiPage Behavior
/// [KhmerText] can be used inside `pw.MultiPage` documents (e.g. as children of
/// columns or containers), but a single [KhmerText] widget instance renders within
/// its allocated box and does not span across multiple pages.
///
/// ### Non-Khmer Fallback
/// Non-Khmer characters that cannot be encoded by the default Latin Type1 font
/// (e.g., emojis, Cyrillic, Arabic) deterministically fall back to `'?'`.
/// To render non-Latin scripts alongside Khmer, supply a Unicode `PdfFont` in [style].
class KhmerText extends pw.Widget {
  /// Text string to render.
  final String text;

  /// Optional typography styling.
  ///
  /// Supported properties:
  /// - [pw.TextStyle.fontSize]: font size in points (default: 12.0). Must be positive.
  /// - [pw.TextStyle.color]: fill color of the text.
  /// - [pw.TextStyle.font]: font used for non-Khmer (Latin/numeric/punctuation) runs.
  ///   Note: `style.font` does NOT replace the Khmer shaping font in v1.
  /// - [pw.TextStyle.height]: line height factor (if [lineHeightFactor] is not provided).
  final pw.TextStyle? style;

  /// Text alignment (left, center, right, start, end).
  ///
  /// Defaults to [pw.TextAlign.left]. Under LTR reading direction,
  /// [pw.TextAlign.start] aligns left and [pw.TextAlign.end] aligns right.
  /// [pw.TextAlign.justify] falls back to left alignment in v1.
  final pw.TextAlign textAlign;

  /// Line height scaling factor.
  ///
  /// Overrides [pw.TextStyle.height] if provided.
  final double? lineHeightFactor;

  final KhmerPdfFont? _font;
  final ByteData? _fontBytes;
  final BattambangShaper? _shaper;

  /// Creates a [KhmerText] widget for rendering Khmer and mixed-script text.
  KhmerText(
    this.text, {
    this.style,
    this.textAlign = pw.TextAlign.left,
    this.lineHeightFactor,
  })  : _font = null,
        _fontBytes = null,
        _shaper = null;

  /// Internal constructor used for testing and dependency injection.
  @internal
  KhmerText.internal(
    this.text, {
    this.style,
    this.textAlign = pw.TextAlign.left,
    this.lineHeightFactor,
    KhmerPdfFont? font,
    ByteData? fontBytes,
    BattambangShaper? shaper,
  })  : _font = font,
        _fontBytes = fontBytes,
        _shaper = shaper;

  KhmerTextLayout? _layout;
  late pw.TextStyle _effectiveStyle;
  late BattambangShaper _effectiveShaper;
  PdfFont? _effectiveLatinFont;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final defaultStyle = pw.Theme.of(context).defaultTextStyle;
    _effectiveStyle = defaultStyle.merge(style);
    final fontSize = _effectiveStyle.fontSize ?? 12.0;
    if (fontSize <= 0 || !fontSize.isFinite) {
      throw ArgumentError.value(fontSize, 'fontSize', 'Font size must be positive and finite.');
    }

    final effectiveHeightFactor = lineHeightFactor ?? _effectiveStyle.height;
    if (effectiveHeightFactor != null && (effectiveHeightFactor <= 0 || !effectiveHeightFactor.isFinite)) {
      throw ArgumentError.value(
        effectiveHeightFactor,
        'lineHeightFactor',
        'Line height factor must be positive and finite.',
      );
    }

    _effectiveShaper = _resolveShaper();
    _effectiveLatinFont = _resolveLatinFont(context);

    final maxWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : double.infinity;

    final breaker = const KhmerLineBreaker();
    final layoutResult = breaker.layout(
      text: text,
      shaper: _effectiveShaper,
      fontSize: fontSize,
      latinFont: _effectiveLatinFont,
      maxWidth: maxWidth,
      lineHeightFactor: lineHeightFactor ?? _effectiveStyle.height,
    );

    _layout = layoutResult;
    final naturalSize = PdfPoint(layoutResult.width, layoutResult.height);
    box = PdfRect.fromPoints(PdfPoint.zero, constraints.constrain(naturalSize));
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    final layout = _layout;
    if (layout == null || layout.lines.isEmpty) return;

    final effectiveKhmerFont = _resolveFont(context.page.pdfDocument);
    final latinFont = _effectiveLatinFont ?? PdfFont.helvetica(context.page.pdfDocument);

    if (_effectiveStyle.color != null) {
      context.canvas.setFillColor(_effectiveStyle.color!);
    }

    final unitsPerEm = _effectiveShaper.metrics.unitsPerEm;

    for (int i = 0; i < layout.lines.length; i++) {
      final line = layout.lines[i];
      if (line.clusters.isEmpty) continue;

      final lineX = _calculateLineX(line.visualWidth);
      final lineY = box!.top - (i * layout.lineHeight) - layout.baselineOffset;

      final visualRuns = line.getVisualRuns(unitsPerEm, latinFont: latinFont);
      double currentX = lineX;

      for (final run in visualRuns) {
        if (run.kind == KhmerVisualRunKind.khmer) {
          if (run.shapedRun != null && run.shapedRun!.glyphs.isNotEmpty) {
            effectiveKhmerFont.drawShapedRun(
              context.page,
              context.canvas,
              run.shapedRun!,
              x: currentX,
              y: lineY,
              fontSize: layout.fontSize,
            );
          }
        } else {
          if (run.text.isNotEmpty) {
            context.canvas.drawString(
              latinFont,
              layout.fontSize,
              run.text,
              currentX,
              lineY,
            );
          }
        }
        currentX += run.width;
      }
    }
  }

  double _calculateLineX(double visualWidth) {
    final availableWidth = box!.width;
    final diff = availableWidth - visualWidth;

    switch (textAlign) {
      case pw.TextAlign.right:
      case pw.TextAlign.end:
        return box!.left + (diff > 0 ? diff : 0.0);
      case pw.TextAlign.center:
        return box!.left + (diff > 0 ? diff / 2.0 : 0.0);
      case pw.TextAlign.left:
      case pw.TextAlign.start:
      case pw.TextAlign.justify:
        return box!.left;
    }
  }

  PdfFont? _resolveLatinFont(pw.Context context) {
    if (_effectiveStyle.font != null) {
      return _effectiveStyle.font!.getFont(context);
    }
    return PdfFont.helvetica(context.page.pdfDocument);
  }

  BattambangShaper _resolveShaper() {
    if (_shaper != null) return _shaper!;
    if (_fontBytes != null) {
      final uint8 = _fontBytes!.buffer.asUint8List(
        _fontBytes!.offsetInBytes,
        _fontBytes!.lengthInBytes,
      );
      return KhmerFontCache.getOrCreateShaper(uint8);
    }
    if (_font != null) {
      final uint8 = _font!.font.bytes.buffer.asUint8List();
      return KhmerFontCache.getOrCreateShaper(uint8);
    }
    return KhmerFontCache.getOrCreateShaper();
  }

  KhmerPdfFont _resolveFont(PdfDocument document) {
    if (_font != null) return _font!;
    if (_fontBytes != null) {
      return KhmerFontCache.getOrCreateFont(document, _fontBytes!);
    }
    return KhmerFontCache.getOrCreateFont(document);
  }
}
