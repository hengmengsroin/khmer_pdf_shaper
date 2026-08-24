import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 1: Long-Document Stress Tests', () {
    test(
        '100 KhmerText widgets in a single document save cleanly and measure performance',
        () async {
      final pdf = pw.Document();
      final stopwatch = Stopwatch()..start();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return List.generate(
              100,
              (i) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: KhmerText(
                  'កថាខណ្ឌទី $i៖ ភាសាខ្មែរ គឺជាភាសាផ្លូវការនៃព្រះរាជាណាចក្រកម្ពុជា។',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      stopwatch.stop();

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(2000));
      expect(stopwatch.elapsedMilliseconds,
          lessThan(3000)); // Well under 3s budget
    });

    test(
        '1,000 KhmerText widgets save without CID overflow or resource duplication',
        () async {
      final pdf = pw.Document();
      final stopwatch = Stopwatch()..start();

      const phrases = [
        'សួស្តីពិភពលោក',
        'កម្ពុជា',
        'ភាសាខ្មែរ',
        'ឯកសារ PDF ស្រស់ស្អាត',
        'Invoice វិក្កយបត្រ #12345',
        'តម្លៃសរុប: \$100.00 រៀល',
        'ព្រះរាជាណាចក្រកម្ពុជា',
        'ជាតិ សាសនា ព្រះមហាក្សត្រ',
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return List.generate(
              1000,
              (i) => KhmerText(
                '[$i] ${phrases[i % phrases.length]} (${i * 10} km)',
                style: const pw.TextStyle(fontSize: 10),
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      stopwatch.stop();

      expect(bytes, isNotEmpty);
      // Ensure PDF size is compact (under 500 KB despite 1,000 widgets)
      expect(bytes.length, lessThan(500 * 1024));
    });

    test('10,000 short Khmer runs stress-test throughput and memory', () async {
      final pdf = pw.Document();
      final stopwatch = Stopwatch()..start();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return List.generate(
              10000,
              (i) => KhmerText(
                'កម្ពុជា $i',
                style: const pw.TextStyle(fontSize: 8),
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      stopwatch.stop();

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(10000));
    });
  });
}
