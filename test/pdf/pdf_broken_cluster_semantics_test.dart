import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:tamil_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:tamil_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('PDF Broken-Cluster Semantics Tests', () {
    late Uint8List fontBytes;
    late BattambangShaper shaper;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
    });

    test('Synthetic dotted circle appears visually (GID 272) but is NEVER emitted into /ToUnicode CMap', () async {
      // Input broken cluster: "\u17D2ក" (subscript Ka without base consonant)
      const brokenText = '\u17D2ក';
      final run = shaper.shapeText(brokenText);

      // Visual glyphs contain dotted circle (GID 272 in Battambang) + subscript Ka (GID 295)
      expect(run.glyphs.any((g) => g.glyphId == 272), isTrue);

      final doc = PdfDocument();
      final page = PdfPage(doc);
      final g = page.getGraphics();
      final font = KhmerPdfFont(doc, fontBytes.buffer.asByteData());

      font.drawShapedRun(page, g, run, x: 50, y: 600, fontSize: 16);
      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);

      // Check all registered Unicode strings in the font
      final allTexts = font.registry.entries.values.map((e) => e.unicodeText).toList();
      for (final text in allTexts) {
        // Dotted circle U+25CC must NOT be present
        expect(text.contains('\u25CC'), isFalse,
            reason: 'Synthetic dotted circle must not contaminate /ToUnicode');
      }

      // The original input text slice "\u17D2ក" must be mapped
      expect(allTexts, contains('\u17D2ក'));
    });

    test('Explicit dotted circle typed by user is preserved in /ToUnicode', () async {
      // Input with user-supplied dotted circle: "\u25CC\u17D2ក"
      const userDottedText = '\u25CC\u17D2ក';
      final run = shaper.shapeText(userDottedText);

      final doc = PdfDocument();
      final page = PdfPage(doc);
      final g = page.getGraphics();
      final font = KhmerPdfFont(doc, fontBytes.buffer.asByteData());

      font.drawShapedRun(page, g, run, x: 50, y: 600, fontSize: 16);
      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);

      final allTexts = font.registry.entries.values.map((e) => e.unicodeText).toList();
      expect(allTexts.any((t) => t.contains('\u25CC')), isTrue,
          reason: 'User-provided dotted circle must be preserved');
    });
  });
}
