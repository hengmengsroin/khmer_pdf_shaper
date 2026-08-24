import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('Repeated Physical GID Structural Tests', () {
    late Uint8List fontBytes;
    late BattambangShaper shaper;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
    });

    test(
        'Same physical GID across different clusters gets distinct CIDs and shares 1 subset glyph',
        () async {
      // In Battambang-Regular:
      // "ក្ក" produces [GID 53 (Ka), GID 295 (subscript Ka)] in cluster "ក្ក"
      // "ង្ក" produces [GID 57 (Ngo), GID 295 (subscript Ka)] in cluster "ង្ក"
      // Physical GID 295 is shared across both words!
      final run1 = shaper.shapeText('ក្ក');
      final run2 = shaper.shapeText('ង្ក');

      expect(run1.glyphs[1].glyphId, equals(295));
      expect(run2.glyphs[1].glyphId, equals(295));

      final doc = PdfDocument();
      final page = PdfPage(doc);
      final g = page.getGraphics();
      final font = KhmerPdfFont(doc, fontBytes.buffer.asByteData());

      font.drawShapedRun(page, g, run1, x: 50, y: 600, fontSize: 16);
      font.drawShapedRun(page, g, run2, x: 50, y: 550, fontSize: 16);

      // Save document to trigger font preparation and subsetting
      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);

      // Verify allocated entries in CID registry:
      // GID 53 in "ក្ក" -> CID 1 (Unicode: "ក្ក")
      // GID 295 in "ក្ក" -> CID 2 (Unicode: "")
      // GID 57 in "ង្ក" -> CID 3 (Unicode: "ង្ក")
      // GID 295 in "ង្ក" -> CID 2 (Unicode: "") [reused secondary mapping]
      final entry1 = font.registry.getByCid(1);
      final entry2 = font.registry.getByCid(2);
      final entry3 = font.registry.getByCid(3);

      expect(entry1, isNotNull);
      expect(entry1!.originalGlyphId, equals(53));
      expect(entry1.unicodeText, equals('ក្ក'));

      expect(entry2, isNotNull);
      expect(entry2!.originalGlyphId, equals(295));
      expect(entry2.unicodeText, equals(''));

      expect(entry3, isNotNull);
      expect(entry3!.originalGlyphId, equals(57));
      expect(entry3.unicodeText, equals('ង្ក'));

      // Verify that total unique GIDs accumulated across both runs is 3 (plus .notdef = 4)
      final usedGids = <int>{
        run1.glyphs[0].glyphId,
        run1.glyphs[1].glyphId,
        run2.glyphs[0].glyphId,
        run2.glyphs[1].glyphId,
      };
      expect(usedGids,
          equals({53, 295, 57})); // Exactly 3 physical glyphs in subset font!
    });
  });
}
