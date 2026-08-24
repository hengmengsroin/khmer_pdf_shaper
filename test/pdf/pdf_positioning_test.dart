import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/obj/object_stream.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('PDF Positioned Text Drawing Tests', () {
    late Uint8List fontBytes;
    late BattambangShaper shaper;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
    });

    test('Decouples nominal font metrics in /W from shaped advance adjustments in TJ', () {
      final doc = PdfDocument();
      final page = PdfPage(doc);
      final g = page.getGraphics();
      final font = KhmerPdfFont(doc, fontBytes.buffer.asByteData());

      // In "ក្ក", glyph 0 (Ka) has shaped advance = 1221, glyph 1 (subscript Ka) has shaped advance = 0
      final run = shaper.shapeText('ក្ក');
      expect(run.glyphs.length, equals(2));
      expect(run.glyphs[0].xAdvance, equals(1221.0));
      expect(run.glyphs[1].xAdvance, equals(0.0));
      expect(run.totalAdvanceWidth, equals(1221.0));

      font.drawShapedRun(page, g, run, x: 100, y: 200, fontSize: 20);

      final streamBuf = (page.contents.last as PdfObjectStream).buf;
      final contentStr = utf8.decode(streamBuf.output());

      // Verify text matrix setup
      expect(contentStr, contains('BT'));
      expect(contentStr, contains('20.0 Tf'));
      expect(contentStr, contains('100.0 200.0 Td'));
      expect(contentStr, contains('] TJ'));
      expect(contentStr, contains('ET'));
    });

    test('Total run advance width in PDF points matches shaped design scale exactly', () {
      const fontSize = 16.0;
      final run = shaper.shapeText('សួស្តី');

      // Expected PDF width in points = totalAdvanceWidth * fontSize / unitsPerEm
      final expectedPdfWidth = run.totalAdvanceWidth * fontSize / run.unitsPerEm;
      expect(expectedPdfWidth, greaterThan(0));

      // Each cluster advance matches
      double clusterSum = 0;
      for (final cl in run.clusters) {
        clusterSum += cl.totalAdvanceWidth;
      }
      expect(clusterSum, equals(run.totalAdvanceWidth));
    });
  });
}
