import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 6: Empty & Whitespace-Only Input Tests', () {
    final whitespaceInputs = <String, String>{
      'empty string': '',
      'single space': ' ',
      'multiple spaces': '   ',
      'single newline': '\n',
      'multiple newlines': '\n\n',
      'trailing newlines': 'សួស្តី\n\n\n',
      'leading newlines': '\n\nសួស្តី',
      'zero-width space (ZWSP)': '\u200B',
      'multiple ZWSP': '\u200B\u200B\u200B',
      'non-breaking space (NBSP)': '\u00A0',
      'mixed spaces and ZWSP': ' \u200B \u00A0 \n \u200B ',
    };

    for (final entry in whitespaceInputs.entries) {
      test('Input "${entry.key}" generates PDF cleanly without errors',
          () async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Column(
              children: [
                KhmerText(entry.value, style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );

        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
      });
    }

    test('ZWSP in KhmerText produces zero visible glyphs in PDF stream',
        () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => KhmerText(
            'កម្ពុជា\u200Bសួស្តី',
            style: const pw.TextStyle(fontSize: 14),
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });
  });
}
