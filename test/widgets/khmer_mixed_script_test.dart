import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:khmer_pdf_shaper/src/layout/khmer_layout_model.dart';
import 'package:khmer_pdf_shaper/src/layout/khmer_line_breaker.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';
import 'package:khmer_pdf_shaper/src/widgets/khmer_text.dart';

void main() {
  group('Part 8: Mixed-Script Paint & Baseline Architecture Tests', () {
    late Uint8List fontBytes;
    late BattambangShaper shaper;
    late KhmerLineBreaker breaker;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
      breaker = const KhmerLineBreaker();
    });

    test(
        'Visual runs separate Latin and Khmer into distinct paint paths for "Invoice សួស្តី 123"',
        () {
      const text = 'Invoice សួស្តី 123';
      const fontSize = 14.0;
      final dummyDoc = PdfDocument();
      final latinFont = PdfFont.helvetica(dummyDoc);

      final layout = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
        latinFont: latinFont,
      );

      expect(layout.lines.length, 1);
      final line = layout.lines.first;
      final visualRuns =
          line.getVisualRuns(shaper.metrics.unitsPerEm, latinFont: latinFont);

      // Must produce exactly 3 visual runs:
      // Run 0: "Invoice " (kind: latin, rendered via canvas.drawString)
      // Run 1: "សួស្តី" (kind: khmer, rendered via khmerFont.drawShapedRun)
      // Run 2: " 123" (kind: latin, rendered via canvas.drawString)
      expect(visualRuns.length, 3);

      expect(visualRuns[0].kind, KhmerVisualRunKind.latin);
      expect(visualRuns[0].text, 'Invoice ');
      expect(visualRuns[0].shapedRun, isNull);
      expect(visualRuns[0].width, greaterThan(0.0));

      expect(visualRuns[1].kind, KhmerVisualRunKind.khmer);
      expect(visualRuns[1].text, 'សួស្តី');
      expect(visualRuns[1].shapedRun, isNotNull);
      expect(visualRuns[1].shapedRun!.clusters.length, 2);
      expect(visualRuns[1].width, greaterThan(0.0));

      expect(visualRuns[2].kind, KhmerVisualRunKind.latin);
      expect(visualRuns[2].text, ' 123');
      expect(visualRuns[2].shapedRun, isNull);
      expect(visualRuns[2].width, greaterThan(0.0));
    });

    test('Visual runs separate "Price: \$10 កម្ពុជា" and "ABCកម្ពុជា123"', () {
      final dummyDoc = PdfDocument();
      final latinFont = PdfFont.helvetica(dummyDoc);

      // Price: $10 កម្ពុជា
      final layoutPrice = breaker.layout(
        text: 'Price: \$10 កម្ពុជា',
        shaper: shaper,
        fontSize: 14.0,
        latinFont: latinFont,
      );
      final priceRuns = layoutPrice.lines.first
          .getVisualRuns(shaper.metrics.unitsPerEm, latinFont: latinFont);
      expect(priceRuns.length, 2);
      expect(priceRuns[0].kind, KhmerVisualRunKind.latin);
      expect(priceRuns[0].text, 'Price: \$10 ');
      expect(priceRuns[1].kind, KhmerVisualRunKind.khmer);
      expect(priceRuns[1].text, 'កម្ពុជា');

      // ABCកម្ពុជា123
      final layoutABC = breaker.layout(
        text: 'ABCកម្ពុជា123',
        shaper: shaper,
        fontSize: 14.0,
        latinFont: latinFont,
      );
      final abcRuns = layoutABC.lines.first
          .getVisualRuns(shaper.metrics.unitsPerEm, latinFont: latinFont);
      expect(abcRuns.length, 3);
      expect(abcRuns[0].kind, KhmerVisualRunKind.latin);
      expect(abcRuns[0].text, 'ABC');
      expect(abcRuns[1].kind, KhmerVisualRunKind.khmer);
      expect(abcRuns[1].text, 'កម្ពុជា');
      expect(abcRuns[2].kind, KhmerVisualRunKind.latin);
      expect(abcRuns[2].text, '123');
    });

    test(
        'Mixed-font baseline math accommodates both Khmer and Latin font metrics',
        () {
      final dummyDoc = PdfDocument();
      final latinFont = PdfFont.helvetica(dummyDoc);
      const fontSize = 16.0;

      final layout = breaker.layout(
        text: 'ABC សួស្តី 123',
        shaper: shaper,
        fontSize: fontSize,
        latinFont: latinFont,
      );

      // Line ascent = max(khmerAscent, latinAscent)
      final khmerAscent = 2500.0 * fontSize / 2048.0;
      final latinAscent = latinFont.ascent * fontSize;
      final expectedAscent =
          khmerAscent > latinAscent ? khmerAscent : latinAscent;
      expect(layout.ascent, closeTo(expectedAscent, 0.001));

      // Line descent = max(khmerDescent, latinDescent)
      final khmerDescent = 1200.0 * fontSize / 2048.0;
      final latinDescent = latinFont.descent.abs() * fontSize;
      final expectedDescent =
          khmerDescent > latinDescent ? khmerDescent : latinDescent;
      expect(layout.descent, closeTo(expectedDescent, 0.001));

      // Total height = ascent + descent
      expect(layout.height, closeTo(expectedAscent + expectedDescent, 0.001));

      // Baseline offset equals line ascent (leaving full headroom for Khmer marks and Latin caps)
      expect(layout.baselineOffset, closeTo(expectedAscent, 0.001));
    });

    test('Renders mixed script documents end-to-end to PDF binary', () async {
      final doc = pw.Document();
      final khmerFont =
          KhmerPdfFont(doc.document, fontBytes.buffer.asByteData());

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                KhmerText.internal('Invoice សួស្តី 123', font: khmerFont),
                pw.SizedBox(height: 10),
                KhmerText.internal('Price: \$10 កម្ពុជា', font: khmerFont),
                pw.SizedBox(height: 10),
                KhmerText.internal('ABCកម្ពុជា123', font: khmerFont),
                pw.SizedBox(height: 10),
                KhmerText.internal('កម្ពុជា@example.com', font: khmerFont),
                pw.SizedBox(height: 10),
                KhmerText.internal('https://example.com/ខ្មែរ',
                    font: khmerFont),
              ],
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes.isNotEmpty, isTrue);

      // Save to scratch for extraction validation
      final outFile = File('.dart_tool/mixed_script_test.pdf');
      outFile.writeAsBytesSync(pdfBytes);
      expect(outFile.existsSync(), isTrue);
    });
  });
}
