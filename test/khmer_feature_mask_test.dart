import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/khmer/khmer_internal.dart';

void main() {
  group('Part 10: Khmer Feature Mask Tests', () {
    test('Base character does not receive post-base feature masks', () {
      final run = KhmerPreprocessor.preprocess('ក');
      expect(run.reorderedChars.length, 1);
      expect(run.reorderedChars[0].features.hasPref, isFalse);
      expect(run.reorderedChars[0].features.hasBlwf, isFalse);
      expect(run.reorderedChars[0].features.hasAbvf, isFalse);
      expect(run.reorderedChars[0].features.hasPstf, isFalse);
      expect(run.reorderedChars[0].features.hasCfar, isFalse);
    });

    test('Post-base marks and vowels receive blwf, abvf, and pstf masks', () {
      final run = KhmerPreprocessor.preprocess('កា');
      expect(run.reorderedChars.length, 2);

      // Base Ka
      expect(run.reorderedChars[0].codePoint, 0x1780);
      expect(run.reorderedChars[0].featureMask, 0);

      // Vowel AA (U+17B6)
      final aa = run.reorderedChars[1];
      expect(aa.codePoint, 0x17B6);
      expect(aa.hasFeature(KhmerFeature.blwf), isTrue);
      expect(aa.hasFeature(KhmerFeature.abvf), isTrue);
      expect(aa.hasFeature(KhmerFeature.pstf), isTrue);
      expect(aa.hasFeature(KhmerFeature.pref), isFalse);
    });

    test('COENG RO receives pref mask in addition to post-base masks', () {
      final run = KhmerPreprocessor.preprocess('ក្រ');
      expect(run.reorderedChars.length, 3);

      final coeng = run.reorderedChars[0];
      final ro = run.reorderedChars[1];
      final ka = run.reorderedChars[2];

      expect(coeng.hasFeature(KhmerFeature.pref), isTrue);
      expect(ro.hasFeature(KhmerFeature.pref), isTrue);
      expect(ka.hasFeature(KhmerFeature.pref), isFalse);
    });

    test('CFAR mask is assigned to subsequent marks when COENG RO is present',
        () {
      // U+1784 (Ngo) + U+17D2 + U+179A (Coeng Ro) + U+17D2 + U+1782 (Coeng Ko)
      // When Coeng Ro is reordered, elements following it in the original stream get CFAR
      const text = '\u1784\u17D2\u179A\u17D2\u1782';
      final run = KhmerPreprocessor.preprocess(text);
      expect(run.reorderedChars.length, 5);

      // Subsequent coeng ko should have CFAR
      final lastSubscript =
          run.reorderedChars.firstWhere((c) => c.codePoint == 0x1782);
      expect(lastSubscript.hasFeature(KhmerFeature.cfar), isTrue);
    });
  });
}
