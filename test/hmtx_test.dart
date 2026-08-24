import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/font/metrics_table.dart';
import 'package:khmer_pdf_shaper/src/font/opentype_reader.dart';

void main() {
  group('Part 4: Metrics Table (head, hhea, maxp, hmtx) Tests', () {
    late MetricsTable metrics;

    setUpAll(() {
      final fontBytes =
          File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
      final font = OpenTypeFont.parse(fontBytes);
      metrics = MetricsTable.parse(
        headReader: font.getTableReader('head'),
        hheaReader: font.getTableReader('hhea'),
        maxpReader: font.getTableReader('maxp'),
        hmtxReader: font.getTableReader('hmtx'),
      );
    });

    test('Parses font header and horizontal metric counts accurately', () {
      expect(metrics.unitsPerEm, 2048);
      expect(metrics.numGlyphs, 356);
      expect(metrics.numberOfHMetrics, 276);
    });

    test('Resolves advance width for regular glyphs in font design units', () {
      expect(metrics.advanceWidthForGlyph(53), 1221); // Ka (uni1780)
      expect(metrics.advanceWidthForGlyph(259), 700); // Space
    });

    test(
        'Reuses final advance width for glyphs beyond numberOfHMetrics (>= 276)',
        () {
      // In Battambang, numberOfHMetrics is 276, last metric at index 275 has advance 0 (combining mark)
      final lastAdvance = metrics.advanceWidthForGlyph(275);
      expect(metrics.advanceWidthForGlyph(276), lastAdvance);
      expect(metrics.advanceWidthForGlyph(300), lastAdvance);
      expect(metrics.advanceWidthForGlyph(355), lastAdvance);
    });

    test('Returns 0 for invalid or out-of-range glyph IDs', () {
      expect(metrics.advanceWidthForGlyph(-1), 0);
      expect(metrics.advanceWidthForGlyph(356), 0);
      expect(metrics.advanceWidthForGlyph(1000), 0);
    });
  });
}
