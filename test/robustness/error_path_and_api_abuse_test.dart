import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:khmer_pdf_shaper/src/font/font_binary_validator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 19 & 20: Error-Path Hardening & API Abuse Tests', () {
    test(
        'FontBinaryValidator throws UnsupportedFontException on corrupted or empty font bytes',
        () {
      expect(
        () => FontBinaryValidator.verifySupportedFont(Uint8List(0)),
        throwsA(isA<UnsupportedFontException>()),
      );

      final fakeBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      expect(
        () => FontBinaryValidator.verifySupportedFont(fakeBytes),
        throwsA(isA<UnsupportedFontException>()),
      );
    });

    test(
        'Public API abuse: 100,000 character long string lays out and saves without crashing',
        () async {
      final longString = 'កម្ពុជា ' * 15000; // ~105,000 characters
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Container(
            width: 400,
            child: KhmerText(
              longString,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });

    test(
        'Public API abuse: zero, negative, NaN, and infinite lineHeightFactor throw ArgumentError',
        () async {
      // 1. Zero lineHeightFactor
      {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => KhmerText('សួស្តី', lineHeightFactor: 0.0),
          ),
        );
        expect(() => pdf.save(), throwsA(isA<ArgumentError>()));
      }

      // 2. Negative lineHeightFactor
      {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => KhmerText('សួស្តី', lineHeightFactor: -1.5),
          ),
        );
        expect(() => pdf.save(), throwsA(isA<ArgumentError>()));
      }

      // 3. NaN lineHeightFactor
      {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) =>
                KhmerText('សួស្តី', lineHeightFactor: double.nan),
          ),
        );
        expect(() => pdf.save(), throwsA(isA<ArgumentError>()));
      }

      // 4. Infinite lineHeightFactor
      {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) =>
                KhmerText('សួស្តី', lineHeightFactor: double.infinity),
          ),
        );
        expect(() => pdf.save(), throwsA(isA<ArgumentError>()));
      }
    });

    test('Public API abuse: invalid style.height throws ArgumentError',
        () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText(
            'សួស្តី',
            style: const pw.TextStyle(height: -2.0),
          ),
        ),
      );
      expect(() => pdf.save(), throwsA(isA<ArgumentError>()));
    });
  });
}
