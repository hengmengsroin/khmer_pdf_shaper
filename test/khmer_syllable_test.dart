import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/khmer/khmer_internal.dart';

void main() {
  group('Part 5 & 6: Khmer Syllable State Machine Tests', () {
    test('Identifies single consonant syllable', () {
      final input = KhmerCharStream.fromText('ក');
      final norm = KhmerNormalizer.normalize(input);
      final syllables = KhmerSyllableParser.parse(norm);

      expect(syllables.length, 1);
      expect(syllables[0].type, KhmerSyllableType.consonantSyllable);
      expect(syllables[0].start, 0);
      expect(syllables[0].end, 1);
    });

    test('Identifies consonant + vowel syllables', () {
      for (final word in ['កា', 'កេ', 'កើ', 'កោ']) {
        final input = KhmerCharStream.fromText(word);
        final norm = KhmerNormalizer.normalize(input);
        final syllables = KhmerSyllableParser.parse(norm);

        expect(syllables.length, 1,
            reason: '$word should be exactly 1 syllable');
        expect(syllables[0].type, KhmerSyllableType.consonantSyllable);
        expect(syllables[0].start, 0);
        expect(syllables[0].end, norm.length);
      }
    });

    test('Identifies subjoined consonants (1, 2, and 3 COENG sequences)', () {
      // Base + 1 COENG: ក្រ
      final kra = KhmerNormalizer.normalize(KhmerCharStream.fromText('ក្រ'));
      final kraSyl = KhmerSyllableParser.parse(kra);
      expect(kraSyl.length, 1);
      expect(kraSyl[0].type, KhmerSyllableType.consonantSyllable);
      expect(kraSyl[0].end, kra.length);

      // Base + 2 COENG: ង្គ្រ
      final ngkro =
          KhmerNormalizer.normalize(KhmerCharStream.fromText('ង្គ្រ'));
      final ngkroSyl = KhmerSyllableParser.parse(ngkro);
      expect(ngkroSyl.length, 1);
      expect(ngkroSyl[0].type, KhmerSyllableType.consonantSyllable);
      expect(ngkroSyl[0].end, ngkro.length);

      // Base + 3 COENG: ក្ក្ខ្គ (Base: Ka, Subscripts: Ka, Kha, Ko)
      final tripleCoeng =
          KhmerNormalizer.normalize(KhmerCharStream.fromText('ក្ក្ខ្គ'));
      final tripleSyl = KhmerSyllableParser.parse(tripleCoeng);
      expect(tripleSyl.length, 1);
      expect(tripleSyl[0].type, KhmerSyllableType.consonantSyllable);
      expect(tripleSyl[0].end, tripleCoeng.length);
    });

    test('Identifies real Khmer words with correct syllable boundaries', () {
      // 1. "សួស្តី" -> Syllable 1: "សួ" (0..2), Syllable 2: "ស្តី" (2..6)
      final suosdey =
          KhmerNormalizer.normalize(KhmerCharStream.fromText('សួស្តី'));
      final suosdeySyl = KhmerSyllableParser.parse(suosdey);
      expect(suosdeySyl.length, 2);
      expect(suosdeySyl[0].type, KhmerSyllableType.consonantSyllable);
      expect(suosdeySyl[0].start, 0);
      expect(suosdeySyl[0].end, 2);
      expect(suosdeySyl[1].type, KhmerSyllableType.consonantSyllable);
      expect(suosdeySyl[1].start, 2);
      expect(suosdeySyl[1].end, 6);

      // 2. "ខ្ញុំ" -> 1 syllable (ខ + ្ + ញ + ុ + ំ)
      final khnhom =
          KhmerNormalizer.normalize(KhmerCharStream.fromText('ខ្ញុំ'));
      final khnhomSyl = KhmerSyllableParser.parse(khnhom);
      expect(khnhomSyl.length, 1);
      expect(khnhomSyl[0].type, KhmerSyllableType.consonantSyllable);
      expect(khnhomSyl[0].end, 5);

      // 3. "កម្ពុជា" -> "ក" (0..1), "ម្ពុ" (1..5), "ជា" (5..7)
      final kampuchea =
          KhmerNormalizer.normalize(KhmerCharStream.fromText('កម្ពុជា'));
      final kampucheaSyl = KhmerSyllableParser.parse(kampuchea);
      expect(kampucheaSyl.length, 3);
      expect(kampucheaSyl[0].start, 0);
      expect(kampucheaSyl[0].end, 1);
      expect(kampucheaSyl[1].start, 1);
      expect(kampucheaSyl[1].end, 5);
      expect(kampucheaSyl[2].start, 5);
      expect(kampucheaSyl[2].end, 7);

      // 4. "សង្គ្រាម" -> "ស" (0..1), "ង្គ្រា" (1..7), "ម" (7..8)
      final sangkream =
          KhmerNormalizer.normalize(KhmerCharStream.fromText('សង្គ្រាម'));
      final sangkreamSyl = KhmerSyllableParser.parse(sangkream);
      expect(sangkreamSyl.length, 3);
      expect(sangkreamSyl[0].start, 0);
      expect(sangkreamSyl[0].end, 1);
      expect(sangkreamSyl[1].start, 1);
      expect(sangkreamSyl[1].end, 7);
      expect(sangkreamSyl[2].start, 7);
      expect(sangkreamSyl[2].end, 8);
    });

    test('Identifies independent vowels as valid syllable heads', () {
      for (final iv in ['ឥ', 'ឦ', 'ឧ', 'ឩ', 'ឯ', 'ឱ']) {
        final norm = KhmerNormalizer.normalize(KhmerCharStream.fromText(iv));
        final syl = KhmerSyllableParser.parse(norm);
        expect(syl.length, 1);
        expect(syl[0].type, KhmerSyllableType.consonantSyllable);
      }
    });

    test('Identifies non-Khmer text, digits, and spaces as nonKhmerCluster',
        () {
      final mixed =
          KhmerNormalizer.normalize(KhmerCharStream.fromText('A 123 !'));
      final syls = KhmerSyllableParser.parse(mixed);
      for (final s in syls) {
        expect(s.type, KhmerSyllableType.nonKhmerCluster);
      }
    });
  });
}
