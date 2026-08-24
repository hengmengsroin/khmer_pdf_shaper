import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import '../shaper/battambang_shaper.dart';
import 'khmer_pdf_font.dart';

/// Document-scoped cache for [KhmerPdfFont] instances and immutable shaper cache.
class KhmerFontCache {
  KhmerFontCache._();

  static final Expando<KhmerPdfFont> _documentFonts = Expando<KhmerPdfFont>();
  static BattambangShaper? _cachedBattambangShaper;

  /// Returns the cached immutable [BattambangShaper], initializing it if needed.
  static BattambangShaper getOrCreateShaper(Uint8List fontBytes) {
    return _cachedBattambangShaper ??= BattambangShaper.fromBytes(fontBytes);
  }

  /// Returns or creates a document-scoped [KhmerPdfFont] strictly tied to [document].
  static KhmerPdfFont getOrCreateFont(PdfDocument document, ByteData fontBytes) {
    var font = _documentFonts[document];
    if (font == null) {
      font = KhmerPdfFont(document, fontBytes);
      _documentFonts[document] = font;
    }
    return font;
  }
}
