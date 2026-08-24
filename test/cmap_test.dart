import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/font/cmap_table.dart';
import 'package:khmer_pdf_shaper/src/font/opentype_reader.dart';

void main() {
  group('Part 3: cmap Format 4 Tests', () {
    late CmapTable cmap;

    setUpAll(() {
      final fontBytes = File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
      final font = OpenTypeFont.parse(fontBytes);
      cmap = CmapTable.parse(font.getTableReader('cmap'));
    });

    test('Maps base Khmer consonants to non-zero glyph IDs', () {
      expect(cmap.glyphIdForCodePoint(0x1780), 53); // Ka
      expect(cmap.glyphIdForCodePoint(0x1781), 54); // Kha
      expect(cmap.glyphIdForCodePoint(0x1782), 55); // Ko
      expect(cmap.glyphIdForCodePoint(0x1784), 57); // Ngo
      expect(cmap.glyphIdForCodePoint(0x179A), 79); // Ro
      expect(cmap.glyphIdForCodePoint(0x17A2), 87); // Qa
    });

    test('Maps Khmer dependent vowels and marks to non-zero glyph IDs', () {
      expect(cmap.glyphIdForCodePoint(0x17B6), 107); // Matra AA
      expect(cmap.glyphIdForCodePoint(0x17B7), 275); // Matra I
      expect(cmap.glyphIdForCodePoint(0x17BB), 280); // Matra U
      expect(cmap.glyphIdForCodePoint(0x17C1), 110); // Matra E
      expect(cmap.glyphIdForCodePoint(0x17D2), 294); // Coeng (Stacker)
      expect(cmap.glyphIdForCodePoint(0x25CC), 272); // Dotted Circle
    });

    test('Maps standard ASCII characters correctly', () {
      expect(cmap.glyphIdForCodePoint(0x0020), 259); // Space
      expect(cmap.glyphIdForCodePoint(0x0041), 1);   // 'A'
    });

    test('Returns 0 (.notdef) for missing or unmapped code points', () {
      expect(cmap.glyphIdForCodePoint(0x1234), 0);
      expect(cmap.glyphIdForCodePoint(0xFFFF), 0);
      expect(cmap.glyphIdForCodePoint(0x100000), 0); // Outside BMP
    });
  });
}
