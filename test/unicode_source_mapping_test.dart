import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/khmer/khmer_internal.dart';

void main() {
  group('Part 2: UTF-16 Source Mapping Tests', () {
    test('Decodes basic ASCII and BMP Khmer characters with 1-unit offsets', () {
      final chars = KhmerCharStream.fromText('Aក');
      expect(chars.length, 2);

      // 'A' -> U+0041, UTF-16 offset 0..1
      expect(chars[0].codePoint, 0x0041);
      expect(chars[0].sourceStart, 0);
      expect(chars[0].sourceEnd, 1);
      expect(chars[0].cluster, 0);
      expect(chars[0].category, KhmerCategory.other);

      // 'ក' -> U+1780, UTF-16 offset 1..2
      expect(chars[1].codePoint, 0x1780);
      expect(chars[1].sourceStart, 1);
      expect(chars[1].sourceEnd, 2);
      expect(chars[1].cluster, 1);
      expect(chars[1].category, KhmerCategory.consonant);
    });

    test('Decodes SMP supplementary plane characters (surrogate pairs) correctly', () {
      // '😀' is U+1F600, taking 2 UTF-16 code units (0..2)
      // 'ក' is U+1780, taking 1 UTF-16 code unit (2..3)
      final chars = KhmerCharStream.fromText('😀ក');
      expect(chars.length, 2);

      expect(chars[0].codePoint, 0x1F600);
      expect(chars[0].sourceStart, 0);
      expect(chars[0].sourceEnd, 2);
      expect(chars[0].cluster, 0);
      expect(chars[0].category, KhmerCategory.other);

      expect(chars[1].codePoint, 0x1780);
      expect(chars[1].sourceStart, 2);
      expect(chars[1].sourceEnd, 3);
      expect(chars[1].cluster, 2);
      expect(chars[1].category, KhmerCategory.consonant);
    });

    test('Decodes mixed Khmer, emoji, and Khmer sequence', () {
      // 'ក' (0..1), '😀' (1..3), 'ខ' (3..4)
      final chars = KhmerCharStream.fromText('ក😀ខ');
      expect(chars.length, 3);

      expect(chars[0].codePoint, 0x1780);
      expect(chars[0].sourceStart, 0);
      expect(chars[0].sourceEnd, 1);

      expect(chars[1].codePoint, 0x1F600);
      expect(chars[1].sourceStart, 1);
      expect(chars[1].sourceEnd, 3);

      expect(chars[2].codePoint, 0x1781);
      expect(chars[2].sourceStart, 3);
      expect(chars[2].sourceEnd, 4);
    });

    test('Decodes multi-syllable Khmer text accurately', () {
      // "សួស្តី" -> ស(0..1) ួ(1..2) ស(2..3) ្(3..4) ត(4..5) ី(5..6)
      const text = 'សួស្តី';
      final chars = KhmerCharStream.fromText(text);
      expect(chars.length, 6);

      expect(chars[0].codePoint, 0x179F);
      expect(chars[0].sourceStart, 0);
      expect(chars[0].sourceEnd, 1);

      expect(chars[1].codePoint, 0x17BD);
      expect(chars[1].sourceStart, 1);
      expect(chars[1].sourceEnd, 2);

      expect(chars[2].codePoint, 0x179F);
      expect(chars[2].sourceStart, 2);
      expect(chars[2].sourceEnd, 3);

      expect(chars[3].codePoint, 0x17D2);
      expect(chars[3].sourceStart, 3);
      expect(chars[3].sourceEnd, 4);

      expect(chars[4].codePoint, 0x178F);
      expect(chars[4].sourceStart, 4);
      expect(chars[4].sourceEnd, 5);

      expect(chars[5].codePoint, 0x17B8);
      expect(chars[5].sourceStart, 5);
      expect(chars[5].sourceEnd, 6);
    });

    test('Decodes empty and whitespace strings', () {
      expect(KhmerCharStream.fromText('').isEmpty, isTrue);

      final ws = KhmerCharStream.fromText('  \t\n ');
      expect(ws.length, 5);
      for (int i = 0; i < ws.length; i++) {
        expect(ws[i].sourceStart, i);
        expect(ws[i].sourceEnd, i + 1);
        expect(ws[i].category, KhmerCategory.other);
      }
    });
  });
}
