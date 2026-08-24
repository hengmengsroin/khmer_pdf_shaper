import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('Part 21: Battambang GSUB Targeted Cases Tests', () {
    late BattambangShaper shaper;

    setUpAll(() {
      final fontBytes = File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
    });

    test('Case 1: ក្រ (COENG RO)', () {
      final run = shaper.shapeText('ក្រ');
      expect(run.glyphs.map((g) => g.glyphId).toList(), [205, 53]);
      expect(run.glyphs.map((g) => g.xAdvance).toList(), [610.0, 1221.0]);
    });

    test('Case 2: ក្ក (Subscript Ka)', () {
      final run = shaper.shapeText('ក្ក');
      expect(run.glyphs.map((g) => g.glyphId).toList(), [53, 295]);
      expect(run.glyphs.map((g) => g.xAdvance).toList(), [1221.0, 0.0]);
    });

    test('Case 3: គ្រែ (COENG RO + Pre-base vowel)', () {
      final run = shaper.shapeText('គ្រែ');
      expect(run.glyphs.map((g) => g.glyphId).toList(), [111, 205, 55]);
      expect(run.glyphs.map((g) => g.xAdvance).toList(), [610.0, 610.0, 1221.0]);
    });

    test('Case 4: កោ (Split vowel OA)', () {
      final run = shaper.shapeText('កោ');
      expect(run.glyphs.map((g) => g.glyphId).toList(), [110, 122, 121]);
      expect(run.glyphs.map((g) => g.xAdvance).toList(), [610.0, 1221.0, 610.0]);
    });

    test('Case 5: ខ្ញុំ (Subscript + Above mark + Below mark)', () {
      final run = shaper.shapeText('ខ្ញុំ');
      expect(run.glyphs.map((g) => g.glyphId).toList(), [54, 302, 329, 284]);
      expect(run.glyphs.map((g) => g.xAdvance).toList(), [1221.0, 0.0, 0.0, 0.0]);
    });

    test('Case 6: សួស្តី (Multi-syllable word)', () {
      final run = shaper.shapeText('សួស្តី');
      expect(run.glyphs.map((g) => g.glyphId).toList(), [84, 282, 84, 307, 277]);
      expect(run.glyphs.map((g) => g.xAdvance).toList(), [1831.0, 0.0, 1831.0, 0.0, 0.0]);
    });

    test('Case 7: កម្ពុជា (Country name)', () {
      final run = shaper.shapeText('កម្ពុជា');
      expect(run.glyphs.map((g) => g.glyphId).toList(), [53, 77, 313, 329, 136, 121]);
      expect(run.glyphs.map((g) => g.xAdvance).toList(), [1221.0, 1221.0, 0.0, 0.0, 1221.0, 610.0]);
    });

    test('Case 8: សង្គ្រាម (Multiple subscripts + COENG RO + post vowel)', () {
      final run = shaper.shapeText('សង្គ្រាម');
      expect(run.glyphs.map((g) => g.glyphId).toList(), [84, 207, 130, 297, 121, 77]);
      expect(run.glyphs.map((g) => g.xAdvance).toList(), [1831.0, 610.0, 1221.0, 0.0, 610.0, 1221.0]);
    });

    test('Case 9: ប៉ា (Register shifter + Post-base vowel)', () {
      final run = shaper.shapeText('ប៉ា');
      expect(run.glyphs.map((g) => g.glyphId).toList(), [162, 285, 121]);
      expect(run.glyphs.map((g) => g.xAdvance).toList(), [1221.0, 0.0, 610.0]);
    });
  });
}
