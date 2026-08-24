import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 13: Comprehensive Visual Regression Document Tests', () {
    late List<Map<String, dynamic>> fixtures;

    setUpAll(() {
      final fixtureFile = File('test/fixtures/khmer_golden_fixtures.json');
      expect(fixtureFile.existsSync(), isTrue);
      final jsonMap = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      fixtures = (jsonMap['fixtures'] as List<dynamic>).cast<Map<String, dynamic>>();
    });

    test('Generates comprehensive golden visual document with 206 fixtures, extremes, mixed scripts and layouts', () async {
      final pdf = pw.Document();

      // Page 1: Title, alignment, extremes, and mixed script
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              KhmerText(
                'ព្រះរាជាណាចក្រកម្ពុជា',
                style: const pw.TextStyle(fontSize: 24, color: PdfColors.indigo900),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              KhmerText(
                'ជាតិ សាសនា ព្រះមហាក្សត្រ',
                style: const pw.TextStyle(fontSize: 16),
                textAlign: pw.TextAlign.center,
              ),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 8),

              // Alignments
              KhmerText('តម្រឹមឆ្វេង (Left Aligned)', textAlign: pw.TextAlign.left),
              KhmerText('តម្រឹមកណ្តាល (Center Aligned)', textAlign: pw.TextAlign.center),
              KhmerText('តម្រឹមស្តាំ (Right Aligned)', textAlign: pw.TextAlign.right),
              pw.SizedBox(height: 8),

              // Mixed script cases
              KhmerText('Invoice សួស្តី 123 | Total: \$100.00 រៀល'),
              KhmerText('Price: \$10.50 កម្ពុជា | Email: info@ខ្មែរ.com'),
              pw.SizedBox(height: 8),

              // Whitespace & Special Spaces
              KhmerText('ចន្លោះធម្មតា: [ក ខ គ] | NBSP: [ក\u00A0ខ\u00A0គ] | ZWSP: [ក\u200Bខ\u200Bគ]'),
              pw.SizedBox(height: 8),

              // Font sizes
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  KhmerText('8pt អក្សរ', style: const pw.TextStyle(fontSize: 8)),
                  KhmerText('12pt អក្សរ', style: const pw.TextStyle(fontSize: 12)),
                  KhmerText('16pt អក្សរ', style: const pw.TextStyle(fontSize: 16)),
                  KhmerText('20pt អក្សរ', style: const pw.TextStyle(fontSize: 20)),
                ],
              ),
            ],
          ),
        ),
      );

      // Pages 2+: All 206 golden fixtures formatted in tables
      final fixtureChunks = <List<Map<String, dynamic>>>[];
      const chunkSize = 25;
      for (int i = 0; i < fixtures.length; i += chunkSize) {
        final end = (i + chunkSize < fixtures.length) ? i + chunkSize : fixtures.length;
        fixtureChunks.add(fixtures.sublist(i, end));
      }

      for (int pageIdx = 0; pageIdx < fixtureChunks.length; pageIdx++) {
        final chunk = fixtureChunks[pageIdx];
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                KhmerText(
                  'កម្រងពាក្យគំរូ 206 Fixtures (ទំព័រទី ${pageIdx + 2} / ${fixtureChunks.length + 1})',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.blue900),
                ),
                pw.Divider(),
                ...chunk.map((f) {
                  final id = f['id'] as String;
                  final category = f['category'] as String;
                  final text = f['text'] as String;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 60,
                          child: KhmerText(id, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ),
                        pw.SizedBox(
                          width: 140,
                          child: KhmerText(category, style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey600)),
                        ),
                        pw.Expanded(
                          child: KhmerText(text, style: const pw.TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);

      final visualFile = File('build/khmer_phase7_visual_golden.pdf');
      visualFile.parent.createSync(recursive: true);
      visualFile.writeAsBytesSync(bytes);
      expect(visualFile.existsSync(), isTrue);
    });
  });
}
