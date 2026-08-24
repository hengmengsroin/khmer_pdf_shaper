import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../layout/khmer_layout_model.dart';
import '../layout/khmer_line_breaker.dart';
import '../pdf/khmer_font_cache.dart';
import '../pdf/khmer_pdf_font.dart';
import '../shaper/battambang_shaper.dart';

/// A `package:pdf` widget that lays out and renders shaped Khmer, Latin, and mixed text.
class KhmerText extends pw.Widget {
  /// Text string to render.
  final String text;

  /// Optional pre-created document-scoped [KhmerPdfFont].
  final KhmerPdfFont? font;

  /// Optional font binary bytes used to resolve/cache font and shaper.
  final ByteData? fontBytes;

  /// Optional typography styling.
  final pw.TextStyle? style;

  /// Text alignment (left, center, right, start, end).
  final pw.TextAlign textAlign;

  /// Reading direction (LTR default).
  final pw.TextDirection textDirection;

  /// Line height scaling factor.
  final double? lineHeightFactor;

  /// Optional custom [BattambangShaper].
  final BattambangShaper? shaper;

  KhmerText(
    this.text, {
    this.font,
    this.fontBytes,
    this.style,
    this.textAlign = pw.TextAlign.left,
    this.textDirection = pw.TextDirection.ltr,
    this.lineHeightFactor,
    this.shaper,
  }) : assert(
          font != null || fontBytes != null || shaper != null,
          'KhmerText requires font, fontBytes, or shaper to be provided.',
        );

  KhmerTextLayout? _layout;
  late pw.TextStyle _effectiveStyle;
  late BattambangShaper _effectiveShaper;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final defaultStyle = pw.Theme.of(context).defaultTextStyle;
    _effectiveStyle = defaultStyle.merge(style);
    final fontSize = _effectiveStyle.fontSize ?? 12.0;

    _effectiveShaper = _resolveShaper();

    final maxWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : double.infinity;

    final breaker = const KhmerLineBreaker();
    final layoutResult = breaker.layout(
      text: text,
      shaper: _effectiveShaper,
      fontSize: fontSize,
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

    final effectiveFont = _resolveFont(context.page.pdfDocument);

    if (_effectiveStyle.color != null) {
      context.canvas.setFillColor(_effectiveStyle.color!);
    }

    final unitsPerEm = _effectiveShaper.metrics.unitsPerEm;

    for (int i = 0; i < layout.lines.length; i++) {
      final line = layout.lines[i];
      if (line.clusters.isEmpty) continue;

      final lineX = _calculateLineX(line.visualWidth);
      final lineY = box!.top - (i * layout.lineHeight) - layout.baselineOffset;

      final lineRun = line.toShapedRun(unitsPerEm);
      if (lineRun.glyphs.isNotEmpty) {
        effectiveFont.drawShapedRun(
          context.page,
          context.canvas,
          lineRun,
          x: lineX,
          y: lineY,
          fontSize: layout.fontSize,
        );
      }
    }
  }

  double _calculateLineX(double visualWidth) {
    final availableWidth = box!.width;
    final diff = availableWidth - visualWidth;

    switch (textAlign) {
      case pw.TextAlign.right:
        return box!.left + (diff > 0 ? diff : 0.0);
      case pw.TextAlign.center:
        return box!.left + (diff > 0 ? diff / 2.0 : 0.0);
      case pw.TextAlign.left:
      case pw.TextAlign.justify:
      case pw.TextAlign.start:
        if (textDirection == pw.TextDirection.rtl) {
          return box!.left + (diff > 0 ? diff : 0.0);
        }
        return box!.left;
      case pw.TextAlign.end:
        if (textDirection == pw.TextDirection.rtl) {
          return box!.left;
        }
        return box!.left + (diff > 0 ? diff : 0.0);
    }
  }

  BattambangShaper _resolveShaper() {
    if (shaper != null) return shaper!;
    if (fontBytes != null) {
      final uint8 = fontBytes!.buffer.asUint8List(
        fontBytes!.offsetInBytes,
        fontBytes!.lengthInBytes,
      );
      return KhmerFontCache.getOrCreateShaper(uint8);
    }
    if (font != null) {
      final uint8 = font!.font.bytes.buffer.asUint8List();
      return KhmerFontCache.getOrCreateShaper(uint8);
    }
    throw StateError('Cannot resolve BattambangShaper for KhmerText');
  }

  KhmerPdfFont _resolveFont(PdfDocument document) {
    if (font != null) return font!;
    if (fontBytes != null) {
      return KhmerFontCache.getOrCreateFont(document, fontBytes!);
    }
    throw StateError('Cannot resolve KhmerPdfFont for KhmerText');
  }
}
