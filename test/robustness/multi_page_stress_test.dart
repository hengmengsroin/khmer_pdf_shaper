import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 2: Multi-Page Document Stress Tests', () {
    test('10-page document with repeated headers, footers, and wrapped blocks',
        () async {
      final pdf = pw.Document();

      for (int pageNum = 1; pageNum <= 10; pageNum++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      KhmerText(
                        'ព្រះរាជាណាចក្រកម្ពុជា - ក្រសួងព័ត៌មាន',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700),
                      ),
                      KhmerText(
                        'ទំព័រទី $pageNum / 10',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 10),

                  // Section Title
                  KhmerText(
                    'ជំពូកទី $pageNum ៖ ការវិវត្តនៃបច្ចេកវិទ្យាព័ត៌មានវិទ្យានៅកម្ពុជា',
                    style: const pw.TextStyle(
                        fontSize: 16, color: PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 8),

                  // Mixed-script block
                  KhmerText(
                    'របាយការណ៍បច្ចេកទេស #KH-$pageNum-2026 | Status: បានអនុម័ត (Approved)',
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.green800),
                  ),
                  pw.SizedBox(height: 12),

                  // Wrapped paragraph
                  KhmerText(
                    'ភាសាខ្មែរជាភាសាមួយដ៏ចំណាស់នៅតំបន់អាស៊ីអាគ្នេយ៍ ដែលមានប្រវត្តិសាស្ត្ររាប់ពាន់ឆ្នាំ។ '
                    'នៅក្នុងយុគសម័យឌីជីថល ការគាំទ្រភាសាខ្មែរលើប្រព័ន្ធកុំព្យូទ័រ និងទូរស័ព្ទដៃ '
                    'មានសារៈសំខាន់បំផុតដើម្បីរក្សា និងលើកកម្ពស់វប្បធម៌ជាតិ។ '
                    'ការបង្កើតឯកសារ PDF ដែលគាំទ្រការបង្ហាញអក្សរខ្មែរបានត្រឹមត្រូវ '
                    'និងអាចស្វែងរកទិន្នន័យបាន គឺជាជំហានដ៏សំខាន់មួយក្នុងការអភិវឌ្ឍរដ្ឋបាលអេឡិចត្រូនិក។',
                    style: const pw.TextStyle(fontSize: 11),
                    lineHeightFactor: 1.5,
                  ),
                  pw.Spacer(),

                  // Footer
                  pw.Divider(thickness: 0.5),
                  KhmerText(
                    'រក្សាសិទ្ធិគ្រប់យ៉ាង © 2026 ក្រសួងព័ត៌មាន',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              );
            },
          ),
        );
      }

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(5000));
    });

    test('100-page document stress generation with single shared font',
        () async {
      final pdf = pw.Document();
      final stopwatch = Stopwatch()..start();

      for (int pageNum = 1; pageNum <= 100; pageNum++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                KhmerText(
                  'ឯកសារគំរូទំព័រទី $pageNum នៃ 100 ទំព័រ',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                KhmerText(
                  'Item $pageNum: តម្លៃទំនិញ \$${pageNum * 10}.00 (បូកបញ្ចូលពន្ធរួច)',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        );
      }

      final bytes = await pdf.save();
      stopwatch.stop();

      expect(bytes, isNotEmpty);
      // Verify size is well within realistic bounds for 100 pages with embedded subset font
      expect(bytes.length, lessThan(300 * 1024));
    });
  });
}
