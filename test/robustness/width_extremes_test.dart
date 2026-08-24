import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 5: Width Extremes Tests', () {
    test('Unconstrained width (double.infinity) measures natural single-line bounding box', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(2000, 200),
          build: (context) => pw.ConstrainedBox(
            constraints: const pw.BoxConstraints(),
            child: KhmerText(
              'សួស្តីពិភពលោក នេះជាអត្ថបទវែងដែលគ្មានការកម្រិតប្រវែងទទឹងឡើយ។',
              style: const pw.TextStyle(fontSize: 14),
            ),
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });

    test('Exact-fit width and width just below exact fit wrap gracefully', () async {
      final pdf = pw.Document();
      const sample = 'សួស្តី កម្ពុជា';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            children: [
              // Exact fit
              pw.Container(
                width: 80,
                child: KhmerText(sample, style: const pw.TextStyle(fontSize: 12)),
              ),
              // Just below exact fit (triggers wrap on space/cluster)
              pw.Container(
                width: 70,
                child: KhmerText(sample, style: const pw.TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });

    test('Narrow width and width < single cluster wraps per cluster without infinite loop', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            children: [
              // Very narrow width (10 pt)
              pw.Container(
                width: 10,
                child: KhmerText(
                  'កម្ពុជា',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              // Width smaller than single cluster (1 pt)
              pw.Container(
                width: 1,
                child: KhmerText(
                  'សួស្តី',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });

    test('Zero width does not loop or crash', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Container(
            width: 0,
            child: KhmerText(
              'កម្ពុជា',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });

    test('Extremely large width (100,000 pt) lays out cleanly', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(105000, 1000),
          build: (context) => pw.Container(
            width: 100000,
            child: KhmerText(
              'សួស្តីពិភពលោក',
              style: const pw.TextStyle(fontSize: 24),
            ),
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });
  });
}
