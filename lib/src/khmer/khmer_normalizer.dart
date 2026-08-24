import 'khmer_category.dart';
import 'khmer_char.dart';

/// Normalizes Khmer text according to HarfBuzz Khmer shaper decomposition rules.
class KhmerNormalizer {
  KhmerNormalizer._();

  /// Decomposes Khmer split-matras while preserving exact UTF-16 source provenance.
  ///
  /// The 5 decomposed split-matras in HarfBuzz Khmer shaper are:
  /// - U+17BE (ើ) -> U+17C1 (េ, VPre) + U+17BE (ើ, VAbv)
  /// - U+17BF (ឿ) -> U+17C1 (េ, VPre) + U+17BF (ឿ, VPst)
  /// - U+17C0 (ៀ) -> U+17C1 (េ, VPre) + U+17C0 (ៀ, VPst)
  /// - U+17C4 (ោ) -> U+17C1 (េ, VPre) + U+17C4 (ោ, VPst)
  /// - U+17C5 (ៅ) -> U+17C1 (េ, VPre) + U+17C5 (ៅ, VPst)
  static List<KhmerChar> normalize(List<KhmerChar> chars) {
    final List<KhmerChar> output = [];

    for (final char in chars) {
      switch (char.codePoint) {
        case 0x17BE: // KHMER VOWEL SIGN OE
          output.add(KhmerChar(
            codePoint: 0x17C1,
            sourceStart: char.sourceStart,
            sourceEnd: char.sourceEnd,
            cluster: char.cluster,
            category: KhmerCategory.vowelPre,
            isSynthetic: true,
            originalCodePoints: [char.codePoint],
          ));
          output.add(KhmerChar(
            codePoint: 0x17BE,
            sourceStart: char.sourceStart,
            sourceEnd: char.sourceEnd,
            cluster: char.cluster,
            category: KhmerCategory.vowelAbove,
            isSynthetic: true,
            originalCodePoints: [char.codePoint],
          ));
          break;

        case 0x17BF: // KHMER VOWEL SIGN YA
          output.add(KhmerChar(
            codePoint: 0x17C1,
            sourceStart: char.sourceStart,
            sourceEnd: char.sourceEnd,
            cluster: char.cluster,
            category: KhmerCategory.vowelPre,
            isSynthetic: true,
            originalCodePoints: [char.codePoint],
          ));
          output.add(KhmerChar(
            codePoint: 0x17BF,
            sourceStart: char.sourceStart,
            sourceEnd: char.sourceEnd,
            cluster: char.cluster,
            category: KhmerCategory.vowelPost,
            isSynthetic: true,
            originalCodePoints: [char.codePoint],
          ));
          break;

        case 0x17C0: // KHMER VOWEL SIGN IE
          output.add(KhmerChar(
            codePoint: 0x17C1,
            sourceStart: char.sourceStart,
            sourceEnd: char.sourceEnd,
            cluster: char.cluster,
            category: KhmerCategory.vowelPre,
            isSynthetic: true,
            originalCodePoints: [char.codePoint],
          ));
          output.add(KhmerChar(
            codePoint: 0x17C0,
            sourceStart: char.sourceStart,
            sourceEnd: char.sourceEnd,
            cluster: char.cluster,
            category: KhmerCategory.vowelPost,
            isSynthetic: true,
            originalCodePoints: [char.codePoint],
          ));
          break;

        case 0x17C4: // KHMER VOWEL SIGN OO
          output.add(KhmerChar(
            codePoint: 0x17C1,
            sourceStart: char.sourceStart,
            sourceEnd: char.sourceEnd,
            cluster: char.cluster,
            category: KhmerCategory.vowelPre,
            isSynthetic: true,
            originalCodePoints: [char.codePoint],
          ));
          output.add(KhmerChar(
            codePoint: 0x17C4,
            sourceStart: char.sourceStart,
            sourceEnd: char.sourceEnd,
            cluster: char.cluster,
            category: KhmerCategory.vowelPost,
            isSynthetic: true,
            originalCodePoints: [char.codePoint],
          ));
          break;

        case 0x17C5: // KHMER VOWEL SIGN AU
          output.add(KhmerChar(
            codePoint: 0x17C1,
            sourceStart: char.sourceStart,
            sourceEnd: char.sourceEnd,
            cluster: char.cluster,
            category: KhmerCategory.vowelPre,
            isSynthetic: true,
            originalCodePoints: [char.codePoint],
          ));
          output.add(KhmerChar(
            codePoint: 0x17C5,
            sourceStart: char.sourceStart,
            sourceEnd: char.sourceEnd,
            cluster: char.cluster,
            category: KhmerCategory.vowelPost,
            isSynthetic: true,
            originalCodePoints: [char.codePoint],
          ));
          break;

        default:
          output.add(char);
          break;
      }
    }

    return output;
  }
}
