import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:tamil_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:tamil_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('PDF Semantics and Multi-Word End-to-End Tests', () {
    late Uint8List fontBytes;
    late BattambangShaper shaper;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
    });

    test('Generates valid PDF containing all 9 golden words plus mixed Latin text', () async {
      final doc = PdfDocument();
      final page = PdfPage(doc, pageFormat: const PdfPageFormat(500, 800));
      final g = page.getGraphics();
      final font = KhmerPdfFont(doc, fontBytes.buffer.asByteData());

      final testWords = [
        'ក្រ',
        'ក្ក',
        'គ្រែ',
        'កោ',
        'ខ្ញុំ',
        'សួស្តី',
        'កម្ពុជា',
        'សង្គ្រាម',
        'ប៉ា',
        'Invoice សួស្តី 123',
      ];

      double y = 750;
      for (final word in testWords) {
        final run = shaper.shapeText(word);
        font.drawShapedRun(page, g, run, x: 50, y: y, fontSize: 16);
        y -= 40;
      }

      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));

      final pdfString = latin1.decode(pdfBytes, allowInvalid: true);

      // Verify Type0 and CIDFontType2 structure in PDF
      expect(pdfString, contains('/Subtype/Type0'));
      expect(pdfString, contains('/Subtype/CIDFontType2'));
      expect(pdfString, contains('/CIDToGIDMap'));
      expect(pdfString, contains('/ToUnicode'));
      expect(pdfString, contains('/FontFile2'));
      expect(pdfString, contains('/Encoding/Identity-H'));

      // Verify that all words are present in font registry
      final registeredTexts = font.registry.entries.values.map((e) => e.unicodeText).toSet();
      for (final word in ['ក្រ', 'ក្ក', 'គ្រែ', 'កោ', 'ខ្ញុំ', 'សួស្តី', 'កម្ពុជា', 'សង្គ្រាម', 'ប៉ា']) {
        expect(registeredTexts.any((t) => word.contains(t) && t.isNotEmpty), isTrue);
      }
    });
  });
}
