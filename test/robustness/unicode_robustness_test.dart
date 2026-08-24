import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Phase 7 — Item 7: Unicode Robustness Tests', () {
    final unicodeCases = <String, String>{
      'valid standard Khmer': 'ព្រះរាជាណាចក្រកម្ពុជា',
      'repeated COENG': '\u1780\u17D2\u17D2\u1780\u17D2\u17D2\u17D2\u1781',
      'leading combining vowel (orphan matra)': '\u17B6\u1780\u17C1\u1780',
      'leading combining sign': '\u17C6\u1780\u17C7\u1780',
      'trailing isolated COENG': 'កម្ពុជា\u17D2',
      'isolated COENG alone': '\u17D2',
      'repeated isolated COENGs': '\u17D2\u17D2\u17D2',
      'zero-width joiner (ZWJ)': 'ក\u200D្\u200Dខ',
      'zero-width non-joiner (ZWNJ)': 'ក\u200C្\u200Cខ',
      'zero-width space (ZWSP)': 'ពាក្យ\u200Bមួយ\u200Bទៀត',
      'non-breaking space (NBSP)': 'តម្លៃ\u00A0១០០\u00A0រៀល',
      'explicit dotted circle input': '\u25CC\u17B6\u25CC\u17D2\u1780',
      'supplementary-plane emoji next to Khmer': 'សួស្តី 😀🎉🇰🇭 កម្ពុជា',
      'Latin + Khmer + emoji': 'Hello 😀 សួស្តី 🇰🇭 123!',
      'combining marks outside Khmer (Latin combining accents)': 'caf\u0065\u0301 na\u0069\u0308ve re\u0301sume\u0301',
    };

    for (final entry in unicodeCases.entries) {
      test('Unicode test case "${entry.key}" shapes and saves to PDF without crashing', () async {
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
  });
}
