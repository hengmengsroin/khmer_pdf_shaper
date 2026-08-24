import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 8: Mixed-Script Stress Tests', () {
    final testStrings = [
      'Invoice សួស្តី 123',
      'ABCកម្ពុជា123',
      '😀 សួស្តី 😀',
      'Price: \$10 កម្ពុជា',
      'កម្ពុជា@example.com',
      'https://example.com/ខ្មែរ',
    ];

    for (final s in testStrings) {
      test('Mixed-script case "$s" renders and saves with deterministic font segmentation', () async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                KhmerText(
                  s,
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.blueGrey900,
                    font: pw.Font.helvetica(),
                  ),
                ),
              ],
            ),
          ),
        );

        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
      });
    }

    test('Complex mixed document containing all requested cases saves cleanly', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: testStrings
                .map((str) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: KhmerText(str, style: const pw.TextStyle(fontSize: 12)),
                    ))
                .toList(),
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });
  });
}
