import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('Part 20: Large Generated Differential Stress Corpus', () {
    late BattambangShaper shaper;
    late List<dynamic> stressFixtures;

    setUpAll(() {
      final fontBytes =
          File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);

      final file = File('test/fixtures/khmer_stress_corpus.json');
      expect(file.existsSync(), isTrue,
          reason: 'Stress fixture file must exist');
      final content = file.readAsStringSync();
      final jsonMap = jsonDecode(content) as Map<String, dynamic>;
      stressFixtures = jsonMap['fixtures'] as List<dynamic>;
    });

    test(
        'Validates 805 generated differential stress cases against HarfBuzz oracle',
        () {
      int passed = 0;
      int failed = 0;
      String? firstFailure;

      for (final f in stressFixtures) {
        final id = f['id'] as String;
        final text = f['text'] as String;
        final expectedGlyphs = f['harfbuzz']['glyphs'] as List<dynamic>;

        final run = shaper.shapeText(text);

        bool match = true;
        if (run.glyphs.length != expectedGlyphs.length) {
          match = false;
        } else {
          for (int i = 0; i < run.glyphs.length; i++) {
            final actual = run.glyphs[i];
            final expected = expectedGlyphs[i];
            if (actual.glyphId != expected['glyph_id'] ||
                actual.cluster != expected['cluster'] ||
                (actual.xAdvance - (expected['x_advance'] as num).toDouble())
                        .abs() >
                    0.001 ||
                actual.yAdvance != (expected['y_advance'] as num).toDouble() ||
                actual.xOffset != (expected['x_offset'] as num).toDouble() ||
                actual.yOffset != (expected['y_offset'] as num).toDouble()) {
              match = false;
              break;
            }
          }
        }

        if (match) {
          passed++;
        } else {
          failed++;
          firstFailure ??= '$id ("$text")';
        }
      }

      // ignore: avoid_print
      print('\n================ STRESS CORPUS REPORT ================');
      // ignore: avoid_print
      print('stress_corpus:');
      // ignore: avoid_print
      print('  cases: ${stressFixtures.length}');
      // ignore: avoid_print
      print('  passed: $passed');
      // ignore: avoid_print
      print('  failed: $failed');
      // ignore: avoid_print
      print('  first_failure: ${firstFailure ?? "none"}');
      // ignore: avoid_print
      print('======================================================\n');

      expect(failed, 0, reason: 'First failure: $firstFailure');
      expect(passed, stressFixtures.length);
    });
  });
}
