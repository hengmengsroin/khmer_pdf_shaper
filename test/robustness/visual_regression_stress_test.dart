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

      // Page 1: Permanent visual regression suite covering all 22 representative categories
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              KhmerText(
                'ព្រះរាជាណាចក្រកម្ពុជា — Visual Regression Suite',
                style: const pw.TextStyle(fontSize: 18, color: PdfColors.indigo900),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              KhmerText(
                'ជាតិ សាសនា ព្រះមហាក្សត្រ',
                style: const pw.TextStyle(fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),
              pw.Divider(thickness: 1.0),

              // 1. Permanent core words & zero-length glyph cases
              KhmerText(
                'Permanent Core Words: សួស្តី | កម្ពុជា | ខ្ញុំ | សង្គ្រាម | ក្រ | ក្ក | គ្រែ | ប៉ា',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 4),

              // 2. Representative categories
              KhmerText('1. Basic & Pre-base: ក ខ គ | គេ តែ កៃ កៅ', style: const pw.TextStyle(fontSize: 10)),
              KhmerText('2. Above & Below Marks: កី កឹ កឺ | គុ គូ គួ', style: const pw.TextStyle(fontSize: 10)),
              KhmerText('3. Split Matras & Robat: កោះ កាំ កុំ | ធម៌ ពណ៌', style: const pw.TextStyle(fontSize: 10)),
              KhmerText('4. Subscripts & COENG RO: ក្ក ក្ខ | ក្រ គ្រ ស្រ', style: const pw.TextStyle(fontSize: 10)),
              KhmerText('5. Stacked Marks & Clusters: ក្ដាំង សង្គ្រាម កញ្ឆា', style: const pw.TextStyle(fontSize: 10)),
              KhmerText('6. Broken Cluster & Dotted Circle: \u25CC\u17B6 | \u17D2\u1780 | \u25CC\u17C1\u1780', style: const pw.TextStyle(fontSize: 10)),
              KhmerText('7. Joiners (ZWJ / ZWNJ): ក\u200D្\u200Dក | ក\u200C្\u200Cក | ឥ\u200Dក', style: const pw.TextStyle(fontSize: 10)),
              KhmerText('8. Spaces (SPACE / NBSP / ZWSP): [ក ខ] | [ក\u00A0ខ] | [ក\u200Bខ]', style: const pw.TextStyle(fontSize: 10)),
              KhmerText('9. Mixed Script: Invoice សួស្តី 123 | \$10 កម្ពុជា | info@ខ្មែរ.com', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),

              // 3. Alignments
              KhmerText('Left Aligned: តម្រឹមឆ្វេង សួស្តី', textAlign: pw.TextAlign.left, style: const pw.TextStyle(fontSize: 10)),
              KhmerText('Center Aligned: តម្រឹមកណ្តាល សួស្តី', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
              KhmerText('Right Aligned: តម្រឹមស្តាំ សួស្តី', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),

              // 4. Wrapping & Font Sizes
              pw.Container(
                width: 250,
                child: KhmerText(
                  'Wrapping Check: ភាសាខ្មែរគឺជាភាសាផ្លូវការនៃព្រះរាជាណាចក្រកម្ពុជា។',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  KhmerText('8pt អក្សរ', style: const pw.TextStyle(fontSize: 8)),
                  KhmerText('10pt អក្សរ', style: const pw.TextStyle(fontSize: 10)),
                  KhmerText('14pt អក្សរ', style: const pw.TextStyle(fontSize: 14)),
                  KhmerText('18pt អក្សរ', style: const pw.TextStyle(fontSize: 18)),
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

      final visualFile = File('build/khmer_phase8_visual_golden.pdf');
      visualFile.parent.createSync(recursive: true);
      visualFile.writeAsBytesSync(bytes);
      expect(visualFile.existsSync(), isTrue);
    });
  });
}
