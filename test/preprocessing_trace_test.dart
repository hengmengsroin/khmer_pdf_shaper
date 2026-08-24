import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/khmer/khmer_internal.dart';

void main() {
  group('Part 11 & 16: Preprocessing Trace and Exit Cases', () {
    test('Produces full formatted trace for គ្រែ', () {
      final run = KhmerPreprocessor.preprocess('គ្រែ');
      final trace = run.generateTrace();

      expect(trace.contains('INPUT'), isTrue);
      expect(trace.contains('NORMALIZED'), isTrue);
      expect(trace.contains('SYLLABLES'), isTrue);
      expect(trace.contains('REORDERED'), isTrue);

      // Verify reordered sequence contains U+17C2, U+17D2, U+179A, U+1782
      expect(run.reorderedChars.map((c) => 'U+${c.codePoint.toRadixString(16).toUpperCase()}').toList(),
          ['U+17C2', 'U+17D2', 'U+179A', 'U+1782']);
    });

    test('Exit Case: ក្រ', () {
      final run = KhmerPreprocessor.preprocess('ក្រ');
      expect(run.reorderedChars.map((c) => c.codePoint).toList(), [0x17D2, 0x179A, 0x1780]);
      expect(run.reorderedChars[0].hasFeature(KhmerFeature.pref), isTrue);
      expect(run.reorderedChars[1].hasFeature(KhmerFeature.pref), isTrue);
      expect(run.reorderedChars[2].hasFeature(KhmerFeature.pref), isFalse);
    });

    test('Exit Case: ក្ក', () {
      final run = KhmerPreprocessor.preprocess('ក្ក');
      expect(run.reorderedChars.map((c) => c.codePoint).toList(), [0x1780, 0x17D2, 0x1780]);
      expect(run.reorderedChars[1].hasFeature(KhmerFeature.blwf), isTrue);
      expect(run.reorderedChars[2].hasFeature(KhmerFeature.blwf), isTrue);
    });

    test('Exit Case: កោ', () {
      final run = KhmerPreprocessor.preprocess('កោ');
      // Decomposed U+17C4 -> U+17C1 + U+17C4, reordered -> U+17C1, U+1780, U+17C4
      expect(run.reorderedChars.map((c) => c.codePoint).toList(), [0x17C1, 0x1780, 0x17C4]);
    });

    test('Exit Case: ខ្ញុំ', () {
      final run = KhmerPreprocessor.preprocess('ខ្ញុំ');
      // [U+1781, U+17D2, U+1789, U+17BB, U+17C6]
      expect(run.reorderedChars.map((c) => c.codePoint).toList(),
          [0x1781, 0x17D2, 0x1789, 0x17BB, 0x17C6]);
      expect(run.reorderedChars[1].hasFeature(KhmerFeature.blwf), isTrue);
      expect(run.reorderedChars[3].hasFeature(KhmerFeature.blwf), isTrue);
      expect(run.reorderedChars[4].hasFeature(KhmerFeature.abvf), isTrue);
    });

    test('Exit Case: សួស្តី', () {
      final run = KhmerPreprocessor.preprocess('សួស្តី');
      expect(run.syllables.length, 2);
      expect(run.reorderedChars.map((c) => c.codePoint).toList(),
          [0x179F, 0x17BD, 0x179F, 0x17D2, 0x178F, 0x17B8]);
    });

    test('Exit Case: កម្ពុជា', () {
      final run = KhmerPreprocessor.preprocess('កម្ពុជា');
      expect(run.syllables.length, 3);
      expect(run.reorderedChars.map((c) => c.codePoint).toList(),
          [0x1780, 0x1798, 0x17D2, 0x1796, 0x17BB, 0x1787, 0x17B6]);
    });

    test('Exit Case: សង្គ្រាម', () {
      final run = KhmerPreprocessor.preprocess('សង្គ្រាម');
      expect(run.syllables.length, 3);
      // Syllable 1: "ស" -> [U+179F]
      // Syllable 2: "ង្គ្រា" -> [U+17D2 (pref), U+179A (pref), U+1784, U+17D2, U+1782, U+17B6]
      // Syllable 3: "ម" -> [U+1798]
      expect(run.reorderedChars.map((c) => c.codePoint).toList(),
          [0x179F, 0x17D2, 0x179A, 0x1784, 0x17D2, 0x1782, 0x17B6, 0x1798]);
    });
  });
}
