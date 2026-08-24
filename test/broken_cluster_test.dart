import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_pdf_shaper/khmer_pdf_shaper.dart';

void main() {
  group('Part 7: Broken-Cluster Dotted Circle Tests', () {
    test('Isolated combining mark produces broken cluster and inserts U+25CC', () {
      final run = KhmerPreprocessor.preprocess('ា');
      expect(run.syllables.length, 1);
      expect(run.syllables[0].type, KhmerSyllableType.brokenCluster);

      // Reordered run should contain: Dotted Circle (U+25CC) + Vowel AA (U+17B6)
      expect(run.reorderedChars.length, 2);
      expect(run.reorderedChars[0].codePoint, 0x25CC);
      expect(run.reorderedChars[0].isSynthetic, isTrue);
      expect(run.reorderedChars[0].category, KhmerCategory.dottedCircle);
      expect(run.reorderedChars[0].sourceStart, 0);
      expect(run.reorderedChars[0].sourceEnd, 1);

      expect(run.reorderedChars[1].codePoint, 0x17B6);
      expect(run.reorderedChars[1].sourceStart, 0);
      expect(run.reorderedChars[1].sourceEnd, 1);
      expect(run.reorderedChars[1].hasFeature(KhmerFeature.pstf), isTrue);
    });

    test('Isolated COENG produces broken cluster and inserts U+25CC', () {
      final run = KhmerPreprocessor.preprocess('្');
      expect(run.syllables.length, 1);
      expect(run.syllables[0].type, KhmerSyllableType.brokenCluster);

      expect(run.reorderedChars.length, 2);
      expect(run.reorderedChars[0].codePoint, 0x25CC);
      expect(run.reorderedChars[0].isSynthetic, isTrue);

      expect(run.reorderedChars[1].codePoint, 0x17D2);
      expect(run.reorderedChars[1].sourceStart, 0);
      expect(run.reorderedChars[1].sourceEnd, 1);
    });

    test('Leading COENG + Consonant (្ក) produces broken cluster with subscript', () {
      final run = KhmerPreprocessor.preprocess('្ក');
      expect(run.syllables.length, 1);
      expect(run.syllables[0].type, KhmerSyllableType.brokenCluster);

      // [U+25CC, U+17D2, U+1780]
      expect(run.reorderedChars.length, 3);
      expect(run.reorderedChars[0].codePoint, 0x25CC);
      expect(run.reorderedChars[0].category, KhmerCategory.dottedCircle);

      expect(run.reorderedChars[1].codePoint, 0x17D2);
      expect(run.reorderedChars[1].hasFeature(KhmerFeature.blwf), isTrue);

      expect(run.reorderedChars[2].codePoint, 0x1780);
      expect(run.reorderedChars[2].hasFeature(KhmerFeature.blwf), isTrue);
    });

    test('Leading COENG + RO (្រ) produces broken cluster with PREF reordering before U+25CC', () {
      final run = KhmerPreprocessor.preprocess('្រ');
      expect(run.syllables.length, 1);
      expect(run.syllables[0].type, KhmerSyllableType.brokenCluster);

      // Reordered order: [U+17D2 (pref), U+179A (pref), U+25CC (base)]
      expect(run.reorderedChars.length, 3);
      expect(run.reorderedChars[0].codePoint, 0x17D2);
      expect(run.reorderedChars[0].hasFeature(KhmerFeature.pref), isTrue);

      expect(run.reorderedChars[1].codePoint, 0x179A);
      expect(run.reorderedChars[1].hasFeature(KhmerFeature.pref), isTrue);

      expect(run.reorderedChars[2].codePoint, 0x25CC);
      expect(run.reorderedChars[2].category, KhmerCategory.dottedCircle);
    });

    test('Trailing COENG on consonant (ក្) is a consonant syllable (no dotted circle)', () {
      final run = KhmerPreprocessor.preprocess('ក្');
      expect(run.syllables.length, 1);
      expect(run.syllables[0].type, KhmerSyllableType.consonantSyllable);

      // No dotted circle should be inserted for valid consonant syllable
      expect(run.reorderedChars.length, 2);
      expect(run.reorderedChars[0].codePoint, 0x1780);
      expect(run.reorderedChars[1].codePoint, 0x17D2);
    });

    test('Does not throw on arbitrary malformed input strings', () {
      const malformedInputs = [
        '្',
        'ា',
        '្ក',
        'ក្',
        'ក្ក្ខ្គ',
        '្្្្',
        'ក\u200C្ក',
        'ក\u200D្ក',
        '៉៊៌',
      ];
      for (final text in malformedInputs) {
        expect(() => KhmerPreprocessor.preprocess(text), returnsNormally);
      }
    });
  });
}
