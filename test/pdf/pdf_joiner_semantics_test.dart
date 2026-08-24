import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:tamil_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:tamil_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('PDF Joiner Semantics (ZWJ / ZWNJ) Tests', () {
    late Uint8List fontBytes;
    late BattambangShaper shaper;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
    });

    test('Preserves ZWJ (U+200D) in /ToUnicode semantic cluster mapping', () async {
      const textWithZwj = 'ក\u200Dខ';
      final run = shaper.shapeText(textWithZwj);

      final doc = PdfDocument();
      final page = PdfPage(doc);
      final g = page.getGraphics();
      final font = KhmerPdfFont(doc, fontBytes.buffer.asByteData());

      font.drawShapedRun(page, g, run, x: 50, y: 600, fontSize: 16);
      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);

      // Verify that the joiner cluster is preserved with U+200D
      final allTexts = font.registry.entries.values.map((e) => e.unicodeText).toList();
      expect(allTexts, contains('\u200D'));
    });

    test('Preserves ZWNJ (U+200C) in /ToUnicode semantic cluster mapping', () async {
      const textWithZwnj = 'ក\u200Cខ';
      final run = shaper.shapeText(textWithZwnj);

      final doc = PdfDocument();
      final page = PdfPage(doc);
      final g = page.getGraphics();
      final font = KhmerPdfFont(doc, fontBytes.buffer.asByteData());

      font.drawShapedRun(page, g, run, x: 50, y: 600, fontSize: 16);
      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);

      final allTexts = font.registry.entries.values.map((e) => e.unicodeText).toList();
      expect(allTexts, contains('\u200C'));
    });
  });
}
