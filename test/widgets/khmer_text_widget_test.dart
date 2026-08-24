import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:khmer_pdf_shaper/src/pdf/khmer_font_cache.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:khmer_pdf_shaper/src/widgets/khmer_text.dart';

void main() {
  group('Part 7: KhmerText Widget Integration Tests', () {
    late Uint8List fontBytes;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
    });

    test('KhmerText renders inside Column, Row, Container, Padding, Expanded', () async {
      final doc = pw.Document();
      final khmerFont = KhmerPdfFont(doc.document, fontBytes.buffer.asByteData());

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('English Header', style: const pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),
                KhmerText.internal(
                  'សួស្តី ព្រះរាជាណាចក្រកម្ពុជា',
                  font: khmerFont,
                  style: const pw.TextStyle(fontSize: 20),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  color: PdfColors.grey200,
                  child: KhmerText.internal(
                    'ខ្ញុំស្រឡាញ់ភាសាខ្មែរ',
                    font: khmerFont,
                    style: const pw.TextStyle(fontSize: 16, color: PdfColors.blue),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: KhmerText.internal(
                          'Invoice សួស្តី 123',
                          font: khmerFont,
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ),
                      pw.Container(width: 40, height: 20, color: PdfColors.amber),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('KhmerText renders inside MultiPage document', () async {
      final doc = pw.Document();
      final khmerFont = KhmerPdfFont(doc.document, fontBytes.buffer.asByteData());

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(level: 0, text: 'MultiPage Document Test'),
              KhmerText.internal(
                'កថាខណ្ឌទីមួយ នៃឯកសារផ្លូវការ',
                font: khmerFont,
                style: const pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 20),
              KhmerText.internal(
                'កថាខណ្ឌទីពីរ នៃឯកសារផ្លូវការ\nបន្ទាត់ថ្មីមួយទៀត',
                font: khmerFont,
                style: const pw.TextStyle(fontSize: 14),
              ),
            ];
          },
        ),
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('Supports left, center, right alignment', () async {
      final doc = pw.Document();
      final khmerFont = KhmerPdfFont(doc.document, fontBytes.buffer.asByteData());

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Container(
                  width: 300,
                  color: PdfColors.grey100,
                  child: KhmerText.internal(
                    'សួស្តី Left',
                    font: khmerFont,
                    textAlign: pw.TextAlign.left,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: 300,
                  color: PdfColors.grey100,
                  child: KhmerText.internal(
                    'សួស្តី Center',
                    font: khmerFont,
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: 300,
                  color: PdfColors.grey100,
                  child: KhmerText.internal(
                    'សួស្តី Right',
                    font: khmerFont,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('KhmerFontCache manages document-scoped font resolution correctly', () {
      final doc1 = PdfDocument();
      final doc2 = PdfDocument();

      final font1 = KhmerFontCache.getOrCreateFont(doc1, fontBytes.buffer.asByteData());
      final font1Again = KhmerFontCache.getOrCreateFont(doc1, fontBytes.buffer.asByteData());
      final font2 = KhmerFontCache.getOrCreateFont(doc2, fontBytes.buffer.asByteData());

      // Same document reuses the exact same font instance
      expect(identical(font1, font1Again), isTrue);

      // Different documents receive different font instances
      expect(identical(font1, font2), isFalse);
    });
  });
}
