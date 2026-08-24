import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import '../font/battambang_font_data.dart';
import '../shaper/battambang_shaper.dart';
import 'khmer_pdf_font.dart';

/// Document-scoped cache for [KhmerPdfFont] instances and immutable shaper cache.
class KhmerFontCache {
  KhmerFontCache._();

  static final Expando<KhmerPdfFont> _documentFonts = Expando<KhmerPdfFont>();
  static BattambangShaper? _cachedBattambangShaper;

  /// Returns the bundled Battambang font bytes (decoded once and cached in memory).
  static Uint8List get bundledFontBytes => getBundledBattambangBytes();

  /// Returns the cached immutable [BattambangShaper], initializing it if needed.
  static BattambangShaper getOrCreateShaper([Uint8List? fontBytes]) {
    final bytes = fontBytes ?? bundledFontBytes;
    if (fontBytes == null || identical(bytes, bundledFontBytes)) {
      return _cachedBattambangShaper ??= BattambangShaper.fromBytes(bytes);
    }
    return BattambangShaper.fromBytes(bytes);
  }

  /// Returns or creates a document-scoped [KhmerPdfFont] strictly tied to [document].
  static KhmerPdfFont getOrCreateFont(PdfDocument document,
      [ByteData? fontBytes]) {
    var font = _documentFonts[document];
    if (font == null) {
      final bytes = fontBytes ?? ByteData.sublistView(bundledFontBytes);
      font = KhmerPdfFont(document, bytes);
      _documentFonts[document] = font;
    }
    return font;
  }
}
