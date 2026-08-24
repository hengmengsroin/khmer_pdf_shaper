import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/layout/khmer_line_breaker.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('Part 3: Shaped Measurement Tests', () {
    late Uint8List fontBytes;
    late BattambangShaper shaper;
    late KhmerLineBreaker breaker;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
      breaker = const KhmerLineBreaker();
    });

    test('Measures shaped width accurately for ក្ក', () {
      const text = 'ក្ក'; // Base Ka + Coeng Ka
      final run = shaper.shapeText(text);
      expect(run.clusters.length, 1);

      // Nominal codepoint cmap width vs shaped width:
      // Nominal: Ka (GID 53) + Coeng (GID 294) + Ka (GID 53) = 1221 + 0 + 1221 = 2442
      // Shaped: Ka (GID 53, adv: 1221) + Subscript Ka (GID 295, adv: 0) = 1221
      expect(run.totalAdvanceWidth, 1221.0);

      const fontSize = 16.0;
      final layout = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
      );

      final expectedWidth = 1221.0 * fontSize / 2048.0;
      expect(layout.width, closeTo(expectedWidth, 0.001));
      expect(layout.lines.first.clusters.first.advanceFontUnits, 1221.0);
    });

    test('Measures shaped width accurately for ក្រ (reordered pre-base subscript)', () {
      const text = 'ក្រ'; // Base Ka + Coeng Ro
      final run = shaper.shapeText(text);
      expect(run.clusters.length, 1);

      // Subscript Ro (GID 205, adv: 610) + Base Ka (GID 53, adv: 1221) = 1831
      expect(run.totalAdvanceWidth, 1831.0);

      const fontSize = 12.0;
      final layout = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
      );

      final expectedWidth = 1831.0 * fontSize / 2048.0;
      expect(layout.width, closeTo(expectedWidth, 0.001));
    });

    test('Measures shaped width accurately for គ្រែ (vowel + subscript + base)', () {
      const text = 'គ្រែ'; // Base Kho + Coeng Ro + Vowel Ae
      final run = shaper.shapeText(text);
      expect(run.clusters.length, 1);

      // Vowel Ae (GID 111, adv: 610) + Subscript Ro (GID 205, adv: 610) + Base Kho (GID 55, adv: 1221) = 2441
      expect(run.totalAdvanceWidth, 2441.0);

      const fontSize = 20.0;
      final layout = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
      );

      final expectedWidth = 2441.0 * fontSize / 2048.0;
      expect(layout.width, closeTo(expectedWidth, 0.001));
    });

    test('Measures shaped width accurately for ខ្ញុំ (complex vertical stack)', () {
      const text = 'ខ្ញុំ'; // Base Kha + Coeng Nyo + Vowel U + Nikahit
      final run = shaper.shapeText(text);
      expect(run.clusters.length, 1);

      // Base Kha (GID 54, adv: 1221) + Subscript Nyo (GID 302, adv: 0) + Vowel U (GID 329, adv: 0) + Nikahit (GID 284, adv: 0) = 1221
      expect(run.totalAdvanceWidth, 1221.0);

      const fontSize = 24.0;
      final layout = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
      );

      final expectedWidth = 1221.0 * fontSize / 2048.0;
      expect(layout.width, closeTo(expectedWidth, 0.001));
    });

    test('Measures shaped width accurately for multi-syllable word សួស្តី', () {
      const text = 'សួស្តី'; // Syllable 1 (សួ) + Syllable 2 (ស្តី)
      final run = shaper.shapeText(text);
      expect(run.clusters.length, 2);

      // Syllable 1: Sa (GID 84, adv: 1831) + Vowel Ua (GID 282, adv: 0) = 1831
      // Syllable 2: Sa (GID 84, adv: 1831) + Coeng Ta (GID 307, adv: 0) + Vowel Ii (GID 277, adv: 0) = 1831
      // Total: 3662
      expect(run.totalAdvanceWidth, 3662.0);

      const fontSize = 18.0;
      final layout = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
      );

      final expectedWidth = 3662.0 * fontSize / 2048.0;
      expect(layout.width, closeTo(expectedWidth, 0.001));
    });
  });
}
