import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/khmer/khmer_internal.dart';

void main() {
  group('Part 3: Split-Matra Decomposition Tests', () {
    test('Decomposes U+17BE (ើ) into U+17C1 (េ, VPre) + U+17BE (ើ, VAbv)', () {
      final input = KhmerCharStream.fromText('កើ');
      expect(input.length, 2);

      final normalized = KhmerNormalizer.normalize(input);
      expect(normalized.length, 3);

      // Base: ក (U+1780)
      expect(normalized[0].codePoint, 0x1780);
      expect(normalized[0].category, KhmerCategory.consonant);
      expect(normalized[0].sourceStart, 0);
      expect(normalized[0].sourceEnd, 1);
      expect(normalized[0].isSynthetic, isFalse);

      // Left piece: េ (U+17C1)
      expect(normalized[1].codePoint, 0x17C1);
      expect(normalized[1].category, KhmerCategory.vowelPre);
      expect(normalized[1].sourceStart, 1);
      expect(normalized[1].sourceEnd, 2);
      expect(normalized[1].isSynthetic, isTrue);
      expect(normalized[1].originalCodePoints, [0x17BE]);

      // Above piece: ើ (U+17BE)
      expect(normalized[2].codePoint, 0x17BE);
      expect(normalized[2].category, KhmerCategory.vowelAbove);
      expect(normalized[2].sourceStart, 1);
      expect(normalized[2].sourceEnd, 2);
      expect(normalized[2].isSynthetic, isTrue);
      expect(normalized[2].originalCodePoints, [0x17BE]);
    });

    test('Decomposes U+17BF (ឿ) into U+17C1 (េ, VPre) + U+17BF (ឿ, VPst)', () {
      final input = KhmerCharStream.fromText('កឿ');
      final normalized = KhmerNormalizer.normalize(input);
      expect(normalized.length, 3);

      expect(normalized[1].codePoint, 0x17C1);
      expect(normalized[1].category, KhmerCategory.vowelPre);
      expect(normalized[1].sourceStart, 1);
      expect(normalized[1].sourceEnd, 2);
      expect(normalized[1].isSynthetic, isTrue);

      expect(normalized[2].codePoint, 0x17BF);
      expect(normalized[2].category, KhmerCategory.vowelPost);
      expect(normalized[2].sourceStart, 1);
      expect(normalized[2].sourceEnd, 2);
      expect(normalized[2].isSynthetic, isTrue);
    });

    test('Decomposes U+17C0 (ៀ) into U+17C1 (េ, VPre) + U+17C0 (ៀ, VPst)', () {
      final input = KhmerCharStream.fromText('កៀ');
      final normalized = KhmerNormalizer.normalize(input);
      expect(normalized.length, 3);

      expect(normalized[1].codePoint, 0x17C1);
      expect(normalized[1].category, KhmerCategory.vowelPre);
      expect(normalized[2].codePoint, 0x17C0);
      expect(normalized[2].category, KhmerCategory.vowelPost);
    });

    test('Decomposes U+17C4 (ោ) into U+17C1 (េ, VPre) + U+17C4 (ោ, VPst)', () {
      final input = KhmerCharStream.fromText('កោ');
      final normalized = KhmerNormalizer.normalize(input);
      expect(normalized.length, 3);

      expect(normalized[1].codePoint, 0x17C1);
      expect(normalized[1].category, KhmerCategory.vowelPre);
      expect(normalized[2].codePoint, 0x17C4);
      expect(normalized[2].category, KhmerCategory.vowelPost);
    });

    test('Decomposes U+17C5 (ៅ) into U+17C1 (េ, VPre) + U+17C5 (ៅ, VPst)', () {
      final input = KhmerCharStream.fromText('កៅ');
      final normalized = KhmerNormalizer.normalize(input);
      expect(normalized.length, 3);

      expect(normalized[1].codePoint, 0x17C1);
      expect(normalized[1].category, KhmerCategory.vowelPre);
      expect(normalized[2].codePoint, 0x17C5);
      expect(normalized[2].category, KhmerCategory.vowelPost);
    });

    test('Non-split matras and plain vowels pass through unmodified', () {
      final input = KhmerCharStream.fromText('កាកិកុកេ');
      final normalized = KhmerNormalizer.normalize(input);
      expect(normalized.length, input.length);
      for (int i = 0; i < input.length; i++) {
        expect(normalized[i].codePoint, input[i].codePoint);
        expect(normalized[i].isSynthetic, isFalse);
      }
    });
  });
}
