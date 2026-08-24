import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/layout/khmer_line_breaker.dart';
import 'package:khmer_pdf_shaper/src/layout/khmer_line_metrics.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('Part 4: Line Height and Vertical Metrics Tests', () {
    const metrics = KhmerLineMetrics();
    late Uint8List fontBytes;
    late BattambangShaper shaper;
    late KhmerLineBreaker breaker;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
      breaker = const KhmerLineBreaker(lineMetrics: metrics);
    });

    test('Derives natural line height directly from Battambang hhea/OS2 metrics', () {
      expect(metrics.fontAscent, 2500);
      expect(metrics.fontDescent, -1200);
      expect(metrics.fontLineGap, 0);
      expect(metrics.unitsPerEm, 2048);

      // (2500 - (-1200) + 0) / 2048 = 3700 / 2048 = 1.806640625
      for (final fontSize in [10.0, 12.0, 18.0, 24.0, 36.0]) {
        final natural = metrics.calculateNaturalLineHeight(fontSize);
        final expected = 3700.0 * fontSize / 2048.0;
        expect(natural, closeTo(expected, 0.0001));

        final ascent = metrics.calculateAscent(fontSize);
        expect(ascent, closeTo(2500.0 * fontSize / 2048.0, 0.0001));

        final descent = metrics.calculateDescent(fontSize);
        expect(descent, closeTo(1200.0 * fontSize / 2048.0, 0.0001));

        final baselineOffset = metrics.calculateBaselineOffset(fontSize);
        expect(baselineOffset, closeTo(ascent, 0.0001));
      }
    });

    test('Applies user lineHeightFactor properly to natural line height', () {
      const fontSize = 16.0;
      final natural = metrics.calculateNaturalLineHeight(fontSize);

      final scaled1_5 = metrics.calculateLineHeight(fontSize, 1.5);
      expect(scaled1_5, closeTo(natural * 1.5, 0.0001));

      final baselineOffset1_5 = metrics.calculateBaselineOffset(fontSize, 1.5);
      final expectedOffset = metrics.calculateAscent(fontSize) + (scaled1_5 - natural) / 2.0;
      expect(baselineOffset1_5, closeTo(expectedOffset, 0.0001));
    });

    test('Ensures sufficient vertical space to avoid clipping for ខ្ញុំ, សួស្តី, ប៉ា across font sizes', () {
      final testWords = ['ខ្ញុំ', 'សួស្តី', 'ប៉ា'];
      final fontSizes = [10.0, 12.0, 18.0, 24.0, 36.0];

      for (final word in testWords) {
        for (final size in fontSizes) {
          final layout = breaker.layout(
            text: word,
            shaper: shaper,
            fontSize: size,
          );

          expect(layout.lines.length, 1);
          final line = layout.lines.first;

          // Line height must be at least 1.8x fontSize to accommodate all stacked diacritics & subscripts
          expect(line.height, greaterThanOrEqualTo(size * 1.8));

          // Baseline offset must leave room above (ascent >= 1.2 * size) and below (descent >= 0.58 * size)
          expect(line.baseline, greaterThanOrEqualTo(size * 1.2));
          final roomBelow = line.height - line.baseline;
          expect(roomBelow, greaterThanOrEqualTo(size * 0.58));
        }
      }
    });
  });
}
