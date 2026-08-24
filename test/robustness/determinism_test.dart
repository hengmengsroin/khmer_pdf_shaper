import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 3: Determinism Tests', () {
    test('Two separate builds of identical document produce identical layout and stream contents', () async {
      Future<Uint8List> buildPdf() async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  KhmerText(
                    'ព្រះរាជាណាចក្រកម្ពុជា',
                    style: const pw.TextStyle(fontSize: 18),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  KhmerText(
                    'Invoice សួស្តី 123 | Total: \$125.00 រៀល',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 10),
                  KhmerText(
                    'ការពិពណ៌នា៖ ភាសាខ្មែរ គឺជាភាសាផ្លូវការរបស់ប្រទេសកម្ពុជា។',
                    style: const pw.TextStyle(fontSize: 12),
                    lineHeightFactor: 1.5,
                  ),
                ],
              );
            },
          ),
        );
        return pdf.save();
      }

      final bytes1 = await buildPdf();
      final bytes2 = await buildPdf();

      expect(bytes1.length, equals(bytes2.length));

      // Note: package:pdf embeds CreationDate / ModDate or /ID hashes in document metadata.
      // If bytes are not 100% bitwise identical due to timestamp metadata,
      // verify that all font tables, stream contents, and text operators match byte-for-byte.
      final str1 = latin1.decode(bytes1);
      final str2 = latin1.decode(bytes2);

      // Strip variable PDF trailer /ID and /CreationDate for bitwise stream equivalence check
      final normalized1 = str1
          .replaceAll(RegExp(r'/CreationDate\s*\([^)]*\)'), '')
          .replaceAll(RegExp(r'/ModDate\s*\([^)]*\)'), '')
          .replaceAll(RegExp(r'/ID\s*\[[^\]]*\]'), '');
      final normalized2 = str2
          .replaceAll(RegExp(r'/CreationDate\s*\([^)]*\)'), '')
          .replaceAll(RegExp(r'/ModDate\s*\([^)]*\)'), '')
          .replaceAll(RegExp(r'/ID\s*\[[^\]]*\]'), '');

      expect(normalized1, equals(normalized2), reason: 'Document streams, subset fonts, and CID mappings must be byte-for-byte deterministic.');
    });
  });
}
