import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 4: Font-Size Extremes Tests', () {
    final validFontSizes = [1.0, 4.0, 8.0, 12.0, 48.0, 72.0, 144.0, 300.0];

    for (final size in validFontSizes) {
      test(
          'Font size $size pt renders without arithmetic overflow or TJ errors',
          () async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a3,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  KhmerText(
                    'សួស្តីកម្ពុជា $size pt',
                    style: pw.TextStyle(fontSize: size),
                  ),
                  KhmerText(
                    'Mixed 123 ABC សួស្តី $size pt',
                    style: pw.TextStyle(fontSize: size),
                  ),
                ],
              );
            },
          ),
        );

        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
      });
    }

    test('Zero font size throws ArgumentError clearly', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText(
            'សួស្តី',
            style: const pw.TextStyle(fontSize: 0),
          ),
        ),
      );
      expect(() => pdf.save(), throwsA(isA<ArgumentError>()));
    });

    test('Negative font size throws ArgumentError clearly', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText(
            'សួស្តី',
            style: const pw.TextStyle(fontSize: -12.5),
          ),
        ),
      );
      expect(() => pdf.save(), throwsA(isA<ArgumentError>()));
    });

    test('NaN font size throws ArgumentError clearly', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText(
            'សួស្តី',
            style: const pw.TextStyle(fontSize: double.nan),
          ),
        ),
      );
      expect(() => pdf.save(), throwsA(isA<ArgumentError>()));
    });

    test('Infinite font size throws ArgumentError clearly', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText(
            'សួស្តី',
            style: const pw.TextStyle(fontSize: double.infinity),
          ),
        ),
      );
      expect(() => pdf.save(), throwsA(isA<ArgumentError>()));
    });
  });
}
