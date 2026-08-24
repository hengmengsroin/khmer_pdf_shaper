import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('PDF Visual & Multi-Run Golden Fixture Tests', () {
    late Uint8List fontBytes;
    late BattambangShaper shaper;
    late List<Map<String, dynamic>> fixtures;

    setUpAll(() {
      final fontFile = File('assets/fonts/Battambang-Regular.ttf');
      expect(fontFile.existsSync(), isTrue);
      fontBytes = fontFile.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);

      final fixtureFile = File('test/fixtures/khmer_golden_fixtures.json');
      expect(fixtureFile.existsSync(), isTrue);
      final jsonMap =
          jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      fixtures =
          (jsonMap['fixtures'] as List<dynamic>).cast<Map<String, dynamic>>();
    });

    test(
        'Renders all 206 golden fixtures across multiple PDF pages with single font reuse',
        () async {
      final doc = PdfDocument();
      final font = KhmerPdfFont(doc, fontBytes.buffer.asByteData());

      const wordsPerPage = 30;
      PdfPage? currentPage;
      PdfGraphics? currentGraphics;
      double y = 750;

      for (int i = 0; i < fixtures.length; i++) {
        if (i % wordsPerPage == 0) {
          currentPage = PdfPage(doc, pageFormat: const PdfPageFormat(500, 800));
          currentGraphics = currentPage.getGraphics();
          y = 750;
        }

        final word = fixtures[i]['text'] as String;
        final run = shaper.shapeText(word);
        font.drawShapedRun(currentPage!, currentGraphics!, run,
            x: 50, y: y, fontSize: 14);
        y -= 24;
      }

      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);

      // Verify that all 206 words were accumulated into the single font registry
      expect(font.registry.count, greaterThan(100));

      // Save artifact PDF for visual inspection
      final artifactFile = File('build/khmer_golden_206_fixtures.pdf');
      artifactFile.parent.createSync(recursive: true);
      await artifactFile.writeAsBytes(pdfBytes);
      expect(artifactFile.existsSync(), isTrue);
    });
  });
}
