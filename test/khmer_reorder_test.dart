import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_pdf_shaper/khmer_pdf_shaper.dart';

void main() {
  group('Part 8 & 9: Khmer Reordering & Cluster Merging Tests', () {
    test('Reorders COENG RO to pre-base position with PREF feature', () {
      // "ក្រ" -> Base: U+1780, Coeng: U+17D2, Ro: U+179A
      final run = KhmerPreprocessor.preprocess('ក្រ');
      expect(run.reorderedChars.length, 3);

      // 1. Coeng (U+17D2) - sourceStart: 1, sourceEnd: 2
      expect(run.reorderedChars[0].codePoint, 0x17D2);
      expect(run.reorderedChars[0].sourceStart, 1);
      expect(run.reorderedChars[0].sourceEnd, 2);
      expect(run.reorderedChars[0].cluster, 0);
      expect(run.reorderedChars[0].hasFeature(KhmerFeature.pref), isTrue);

      // 2. Ro (U+179A) - sourceStart: 2, sourceEnd: 3
      expect(run.reorderedChars[1].codePoint, 0x179A);
      expect(run.reorderedChars[1].sourceStart, 2);
      expect(run.reorderedChars[1].sourceEnd, 3);
      expect(run.reorderedChars[1].cluster, 0);
      expect(run.reorderedChars[1].hasFeature(KhmerFeature.pref), isTrue);

      // 3. Ka (U+1780) - sourceStart: 0, sourceEnd: 1
      expect(run.reorderedChars[2].codePoint, 0x1780);
      expect(run.reorderedChars[2].sourceStart, 0);
      expect(run.reorderedChars[2].sourceEnd, 1);
      expect(run.reorderedChars[2].cluster, 0);
      expect(run.reorderedChars[2].hasFeature(KhmerFeature.pref), isFalse);
    });

    test('Reorders pre-base vowel (VPre) to start of syllable', () {
      // "កេ" -> Base: U+1780 (0..1), VPre: U+17C1 (1..2)
      final run = KhmerPreprocessor.preprocess('កេ');
      expect(run.reorderedChars.length, 2);

      // VPre (U+17C1) is at index 0, but retains sourceStart: 1, sourceEnd: 2
      expect(run.reorderedChars[0].codePoint, 0x17C1);
      expect(run.reorderedChars[0].sourceStart, 1);
      expect(run.reorderedChars[0].sourceEnd, 2);
      expect(run.reorderedChars[0].cluster, 0);

      // Base (U+1780) is at index 1, retains sourceStart: 0, sourceEnd: 1
      expect(run.reorderedChars[1].codePoint, 0x1780);
      expect(run.reorderedChars[1].sourceStart, 0);
      expect(run.reorderedChars[1].sourceEnd, 1);
      expect(run.reorderedChars[1].cluster, 0);
    });

    test('Reorders combined COENG RO + VPre (គ្រែ) correctly', () {
      // "គ្រែ" -> U+1782 (0..1), U+17D2 (1..2), U+179A (2..3), U+17C2 (3..4)
      final run = KhmerPreprocessor.preprocess('គ្រែ');
      expect(run.reorderedChars.length, 4);

      // 1. VPre: U+17C2 (source: 3..4, cluster: 0)
      expect(run.reorderedChars[0].codePoint, 0x17C2);
      expect(run.reorderedChars[0].sourceStart, 3);
      expect(run.reorderedChars[0].sourceEnd, 4);
      expect(run.reorderedChars[0].cluster, 0);

      // 2. Coeng: U+17D2 (source: 1..2, cluster: 0, pref: true)
      expect(run.reorderedChars[1].codePoint, 0x17D2);
      expect(run.reorderedChars[1].sourceStart, 1);
      expect(run.reorderedChars[1].sourceEnd, 2);
      expect(run.reorderedChars[1].cluster, 0);
      expect(run.reorderedChars[1].hasFeature(KhmerFeature.pref), isTrue);

      // 3. Ro: U+179A (source: 2..3, cluster: 0, pref: true)
      expect(run.reorderedChars[2].codePoint, 0x179A);
      expect(run.reorderedChars[2].sourceStart, 2);
      expect(run.reorderedChars[2].sourceEnd, 3);
      expect(run.reorderedChars[2].cluster, 0);
      expect(run.reorderedChars[2].hasFeature(KhmerFeature.pref), isTrue);

      // 4. Ko: U+1782 (source: 0..1, cluster: 0)
      expect(run.reorderedChars[3].codePoint, 0x1782);
      expect(run.reorderedChars[3].sourceStart, 0);
      expect(run.reorderedChars[3].sourceEnd, 1);
      expect(run.reorderedChars[3].cluster, 0);
    });

    test('Reorders decomposed split matra (កើ) correctly', () {
      // "កើ" -> U+1780 (0..1), U+17BE (1..2 decomposed to U+17C1 + U+17BE)
      final run = KhmerPreprocessor.preprocess('កើ');
      expect(run.reorderedChars.length, 3);

      // Reordered order: U+17C1, U+1780, U+17BE
      expect(run.reorderedChars[0].codePoint, 0x17C1);
      expect(run.reorderedChars[0].sourceStart, 1);
      expect(run.reorderedChars[0].sourceEnd, 2);
      expect(run.reorderedChars[0].isSynthetic, isTrue);

      expect(run.reorderedChars[1].codePoint, 0x1780);
      expect(run.reorderedChars[1].sourceStart, 0);
      expect(run.reorderedChars[1].sourceEnd, 1);

      expect(run.reorderedChars[2].codePoint, 0x17BE);
      expect(run.reorderedChars[2].sourceStart, 1);
      expect(run.reorderedChars[2].sourceEnd, 2);
      expect(run.reorderedChars[2].isSynthetic, isTrue);
    });

    test('Non-Ro subjoined consonants remain below base', () {
      // "ក្ក" -> U+1780 (0..1), U+17D2 (1..2), U+1780 (2..3)
      final run = KhmerPreprocessor.preprocess('ក្ក');
      expect(run.reorderedChars.length, 3);

      // Stays: U+1780, U+17D2, U+1780
      expect(run.reorderedChars[0].codePoint, 0x1780);
      expect(run.reorderedChars[1].codePoint, 0x17D2);
      expect(run.reorderedChars[2].codePoint, 0x1780);

      expect(run.reorderedChars[1].hasFeature(KhmerFeature.blwf), isTrue);
      expect(run.reorderedChars[2].hasFeature(KhmerFeature.blwf), isTrue);
      expect(run.reorderedChars[1].hasFeature(KhmerFeature.pref), isFalse);
    });
  });
}
