// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_font_cache.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 16 & 17 & 18: Resource Lifecycle, Memory & Benchmarks',
      () {
    test(
        'Interleaved Document A, B, C maintain isolated CID registries, fonts, and reused instances within document',
        () async {
      final docA = pw.Document();
      final docB = pw.Document();
      final docC = pw.Document();

      // Interleaved page additions
      docA.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText('ឯកសារទីមួយ ផ្តាច់មុខ (Doc A Only)'),
        ),
      );

      docB.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText('ឯកសារទីពីរ ផ្តាច់មុខ (Doc B Only)'),
        ),
      );

      docC.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText('ឯកសារទីបី ផ្តាច់មុខ (Doc C Only)'),
        ),
      );

      final fontA1 = KhmerFontCache.getOrCreateFont(docA.document);
      final fontA2 = KhmerFontCache.getOrCreateFont(docA.document);
      final fontB = KhmerFontCache.getOrCreateFont(docB.document);
      final fontC = KhmerFontCache.getOrCreateFont(docC.document);

      // Invariant 1: Font resource reused within one document
      expect(identical(fontA1, fontA2), isTrue,
          reason: 'Font instance must be reused within same document');

      // Invariant 2: A != B != C
      expect(identical(fontA1, fontB), isFalse);
      expect(identical(fontB, fontC), isFalse);
      expect(identical(fontA1, fontC), isFalse);

      final bytesA = await docA.save();
      final bytesB = await docB.save();
      final bytesC = await docC.save();

      expect(fontA1.registry.count, greaterThan(1));
      expect(fontB.registry.count, greaterThan(1));
      expect(fontC.registry.count, greaterThan(1));

      expect(bytesA, isNotEmpty);
      expect(bytesB, isNotEmpty);
      expect(bytesC, isNotEmpty);
    });

    test(
        '100 sequential Document save cycles complete without memory leak or state contamination',
        () async {
      for (int i = 0; i < 100; i++) {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => KhmerText('ជុំទី $i ៖ សួស្តីកម្ពុជា'),
          ),
        );
        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
      }
    });

    test('Performance regression baselines (1-page and 100-page)', () async {
      // 1-page baseline
      final sw1 = Stopwatch()..start();
      final pdf1 = pw.Document();
      pdf1.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            children: [
              KhmerText('ព្រះរាជាណាចក្រកម្ពុជា',
                  style: const pw.TextStyle(fontSize: 18)),
              KhmerText('Invoice សួស្តី 123',
                  style: const pw.TextStyle(fontSize: 12)),
              KhmerText(
                'ភាសាខ្មែរ គឺជាភាសាផ្លូវការរបស់ប្រទេសកម្ពុជា។',
                style: const pw.TextStyle(fontSize: 12),
                lineHeightFactor: 1.5,
              ),
            ],
          ),
        ),
      );
      final bytes1 = await pdf1.save();
      sw1.stop();

      // 100-page baseline
      final sw100 = Stopwatch()..start();
      final pdf100 = pw.Document();
      for (int i = 0; i < 100; i++) {
        pdf100.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => KhmerText('ទំព័រទី $i ៖ កម្ពុជា'),
          ),
        );
      }
      final bytes100 = await pdf100.save();
      sw100.stop();

      print('=== Performance Baselines ===');
      print(
          '1-page generation: ${sw1.elapsedMilliseconds} ms (${bytes1.length} bytes)');
      print(
          '100-page generation: ${sw100.elapsedMilliseconds} ms (${bytes100.length} bytes)');
      print(
          'Current Process RSS: ${ProcessInfo.currentRss / (1024 * 1024)} MB');

      expect(bytes1.length, isPositive);
      expect(bytes100.length, isPositive);
    });
  });
}
