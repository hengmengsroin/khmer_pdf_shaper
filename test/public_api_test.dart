import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Part 1: Pure Public API Tests (No /src/ imports)', () {
    test('Zero-configuration KhmerText widget renders cleanly', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: KhmerText(
              'សួស្តី ពិភពលោក',
              style: const pw.TextStyle(fontSize: 24),
            ),
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('Mixed Khmer and Latin text renders cleanly ("Invoice សួស្តី 123")',
        () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            children: [
              KhmerText(
                'Invoice សួស្តី 123',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.blue900,
                  font: pw.Font.helvetica(),
                ),
              ),
              KhmerText(
                'Total: \$125.00 រៀល',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });

    test('Wrapping multi-line Khmer text within bounded constraints', () async {
      final pdf = pw.Document();
      const longText = 'ភាសាខ្មែរ គឺជាភាសាផ្លូវការរបស់ប្រទេសកម្ពុជា '
          'ហើយត្រូវបានប្រើប្រាស់ដោយប្រជាជនខ្មែរទូទាំងពិភពលោក។ '
          'ការបង្កើតឯកសារ PDF ជាភាសាខ្មែរត្រូវតែមានភាពត្រឹមត្រូវ។';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Container(
            width: 200,
            child: KhmerText(
              longText,
              style: const pw.TextStyle(fontSize: 12),
              lineHeightFactor: 1.5,
            ),
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });

    test('Alignment modes: left, center, right, start, end', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              KhmerText('Left Aligned សួស្តី', textAlign: pw.TextAlign.left),
              KhmerText('Center Aligned សួស្តី',
                  textAlign: pw.TextAlign.center),
              KhmerText('Right Aligned សួស្តី', textAlign: pw.TextAlign.right),
              KhmerText('Start Aligned សួស្តី', textAlign: pw.TextAlign.start),
              KhmerText('End Aligned សួស្តី', textAlign: pw.TextAlign.end),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });

    test('Two separate PdfDocuments maintain isolated font caches', () async {
      final pdf1 = pw.Document();
      pdf1.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText('ឯកសារទីមួយ'),
        ),
      );

      final pdf2 = pw.Document();
      pdf2.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText('ឯកសារទីពីរ'),
        ),
      );

      final bytes1 = await pdf1.save();
      final bytes2 = await pdf2.save();

      expect(bytes1, isNotEmpty);
      expect(bytes2, isNotEmpty);
      expect(bytes1, isNot(equals(bytes2)));
    });

    test('Zero-length text string renders without error', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText(''),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });

    test('Invalid font size throws ArgumentError', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText(
            'សួស្តី',
            style: const pw.TextStyle(fontSize: -5),
          ),
        ),
      );
      expect(
        () => pdf.save(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
