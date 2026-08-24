import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/khmer/khmer_internal.dart';

void main() {
  group('Part 4: Character Categorization Tests', () {
    test('All Khmer consonants match HarfBuzz category', () {
      // 0x1780..0x1799 -> Consonant
      for (int cp = 0x1780; cp <= 0x1799; cp++) {
        expect(getKhmerCategory(cp), KhmerCategory.consonant,
            reason:
                'U+${cp.toRadixString(16).toUpperCase()} must be consonant');
      }

      // 0x179A -> Ra
      expect(getKhmerCategory(0x179A), KhmerCategory.ra);

      // 0x179B..0x17A0, 0x17A2 -> Consonant
      for (int cp = 0x179B; cp <= 0x17A0; cp++) {
        expect(getKhmerCategory(cp), KhmerCategory.consonant,
            reason:
                'U+${cp.toRadixString(16).toUpperCase()} must be consonant');
      }
      expect(getKhmerCategory(0x17A1), KhmerCategory.placeholder,
          reason: 'U+17A1 (LA) is base-only consonant matching HarfBuzz OT_GB');
      expect(getKhmerCategory(0x17A2), KhmerCategory.consonant,
          reason: 'U+17A2 (QA) must be consonant');
    });

    test('All Khmer independent vowels match HarfBuzz category', () {
      for (int cp = 0x17A3; cp <= 0x17B3; cp++) {
        expect(getKhmerCategory(cp), KhmerCategory.independentVowel,
            reason:
                'U+${cp.toRadixString(16).toUpperCase()} must be independent vowel');
      }
    });

    test('All Khmer dependent vowels match HarfBuzz categories', () {
      // Post-base vowel AA
      expect(getKhmerCategory(0x17B6), KhmerCategory.vowelPost);

      // Above vowels I, II, Y, YY
      for (int cp = 0x17B7; cp <= 0x17BA; cp++) {
        expect(getKhmerCategory(cp), KhmerCategory.vowelAbove,
            reason:
                'U+${cp.toRadixString(16).toUpperCase()} must be vowelAbove');
      }

      // Below vowels U, UU, UA
      for (int cp = 0x17BB; cp <= 0x17BD; cp++) {
        expect(getKhmerCategory(cp), KhmerCategory.vowelBelow,
            reason:
                'U+${cp.toRadixString(16).toUpperCase()} must be vowelBelow');
      }

      // Pre-base vowels E, AE, AI
      for (int cp = 0x17C1; cp <= 0x17C3; cp++) {
        expect(getKhmerCategory(cp), KhmerCategory.vowelPre,
            reason: 'U+${cp.toRadixString(16).toUpperCase()} must be vowelPre');
      }

      // Split matra positional categories before decomposition
      expect(getKhmerCategory(0x17BE), KhmerCategory.vowelAbove);
      expect(getKhmerCategory(0x17BF), KhmerCategory.vowelPost);
      expect(getKhmerCategory(0x17C0), KhmerCategory.vowelPost);
      expect(getKhmerCategory(0x17C4), KhmerCategory.vowelPost);
      expect(getKhmerCategory(0x17C5), KhmerCategory.vowelPost);
    });

    test('Coeng / Invisible Stacker matches HarfBuzz category', () {
      expect(getKhmerCategory(0x17D2), KhmerCategory.coeng);
    });

    test('Robatic characters match HarfBuzz category', () {
      // Muusikatoan (0x17C9) and Triisap (0x17CA)
      expect(getKhmerCategory(0x17C9), KhmerCategory.robatic);
      expect(getKhmerCategory(0x17CA), KhmerCategory.robatic);

      // Robat (0x17CC)
      expect(getKhmerCategory(0x17CC), KhmerCategory.robatic);
    });

    test('Xgroup modifiers match HarfBuzz category', () {
      const xGroupPoints = [
        0x17C6, // Nikahit
        0x17CB, // Bantoc
        0x17CD, // Toandakhiat
        0x17CE, // Kakabat
        0x17CF, // Ahsda
        0x17D0, // Samyok Sannya
        0x17D1, // Viriam
      ];
      for (final cp in xGroupPoints) {
        expect(getKhmerCategory(cp), KhmerCategory.xGroup,
            reason: 'U+${cp.toRadixString(16).toUpperCase()} must be xGroup');
      }
    });

    test('Ygroup modifiers match HarfBuzz category', () {
      const yGroupPoints = [
        0x17C7, // Reahmuk
        0x17C8, // Yuukaleapintu
        0x17D3, // Bathamasat
        0x17DD, // Atthacan
      ];
      for (final cp in yGroupPoints) {
        expect(getKhmerCategory(cp), KhmerCategory.yGroup,
            reason: 'U+${cp.toRadixString(16).toUpperCase()} must be yGroup');
      }
    });

    test('Placeholders and digits match HarfBuzz category', () {
      // Khmer digits 0..9 -> PLACEHOLDER
      for (int cp = 0x17E0; cp <= 0x17E9; cp++) {
        expect(getKhmerCategory(cp), KhmerCategory.placeholder,
            reason:
                'U+${cp.toRadixString(16).toUpperCase()} must be placeholder');
      }

      // Phnaek Muan (0x17D9)
      expect(getKhmerCategory(0x17D9), KhmerCategory.placeholder);

      // Common placeholders (NBSP, bullet, dashes, geometric shapes)
      expect(getKhmerCategory(0x00A0), KhmerCategory.placeholder);
      expect(getKhmerCategory(0x2015), KhmerCategory.placeholder);
      expect(getKhmerCategory(0x2022), KhmerCategory.placeholder);
      expect(getKhmerCategory(0x25FB), KhmerCategory.placeholder);
      expect(getKhmerCategory(0x25FC), KhmerCategory.placeholder);
      expect(getKhmerCategory(0x25FD), KhmerCategory.placeholder);
      expect(getKhmerCategory(0x25FE), KhmerCategory.placeholder);
    });

    test('Dotted Circle and Joiners match HarfBuzz category', () {
      expect(getKhmerCategory(0x25CC), KhmerCategory.dottedCircle);
      expect(getKhmerCategory(0x200C), KhmerCategory.zwnj);
      expect(getKhmerCategory(0x200D), KhmerCategory.zwj);
    });

    test('Punctuation, Latin, and unrelated scripts map to other', () {
      // Khmer punctuation (Khan, Bariyoosan, Camnuc Pii Kuuh, Lek Too, Beyyal)
      for (int cp = 0x17D4; cp <= 0x17D8; cp++) {
        expect(getKhmerCategory(cp), KhmerCategory.other);
      }
      expect(getKhmerCategory(0x17DA), KhmerCategory.other);
      expect(getKhmerCategory(0x17DB), KhmerCategory.other);

      // Khmer Symbols (0x19E0..0x19FF)
      for (int cp = 0x19E0; cp <= 0x19FF; cp++) {
        expect(getKhmerCategory(cp), KhmerCategory.other);
      }

      // Latin
      expect(getKhmerCategory(0x0041), KhmerCategory.other); // 'A'
      expect(getKhmerCategory(0x0020), KhmerCategory.other); // ' '
      expect(getKhmerCategory(0x0030), KhmerCategory.other); // '0'
    });
  });
}
