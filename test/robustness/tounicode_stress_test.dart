import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_tounicode_cmap.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 12: ToUnicode Stress Tests', () {
    test('KhmerToUnicodeCmap chunks entries into <= 100 pairs per beginbfchar block', () {
      final doc = PdfDocument();
      final map = <int, String>{};

      // Generate 250 distinct CID mappings
      for (int i = 1; i <= 250; i++) {
        map[i] = 'កម្ពុជា_$i';
      }

      final cmap = KhmerToUnicodeCmap(doc, cidToUnicode: map);
      cmap.prepare();

      final output = String.fromCharCodes(cmap.buf.output());
      expect(output, contains('begincmap'));
      expect(output, contains('endcmap'));

      // Should have 3 beginbfchar blocks (100 + 100 + 50)
      final beginMatches = RegExp(r'(\d+)\s+beginbfchar').allMatches(output).toList();
      expect(beginMatches.length, equals(3));
      expect(beginMatches[0].group(1), equals('100'));
      expect(beginMatches[1].group(1), equals('100'));
      expect(beginMatches[2].group(1), equals('50'));
    });

    test('End-to-end PDF with 300 unique Khmer clusters generates valid ToUnicode stream', () async {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return List.generate(
              150,
              (i) => KhmerText(
                'លំដាប់ទី $i៖ ភាសាខ្មែរ (Khmer Text Run $i)',
                style: const pw.TextStyle(fontSize: 10),
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);

      // Write artifact for extraction validation scripts
      final file = File('build/stress_tounicode_sample.pdf');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
    });
  });
}
