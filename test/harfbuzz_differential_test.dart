import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_pdf_shaper/src/gsub/gsub_evaluator.dart';
import 'package:tamil_pdf_shaper/src/gsub/gsub_tables.dart';
import 'package:tamil_pdf_shaper/src/shaper/battambang_shaper.dart';

class DiagnosticTraceLogger implements GsubTraceLogger {
  final stages = <String, List<int>>{};
  final lookupLogs = <String>[];

  @override
  void logStage(String stageName, List<ShapingGlyph> buffer) {
    stages[stageName] = buffer.map((g) => g.glyphId).toList();
  }

  @override
  void logLookup(
    int lookupIndex,
    String featureTag,
    int position,
    List<ShapingGlyph> bufferBefore,
    List<ShapingGlyph> bufferAfter,
  ) {
    final beforeGids = bufferBefore.map((g) => g.glyphId).toList();
    final afterGids = bufferAfter.map((g) => g.glyphId).toList();
    lookupLogs.add('Lookup $lookupIndex ($featureTag) @ $position: $beforeGids -> $afterGids');
  }
}

void main() {
  group('Part 19: HarfBuzz Differential Oracle Validation', () {
    late BattambangShaper shaper;
    late Map<String, dynamic> jsonCorpus;
    late List<dynamic> fixtures;

    setUpAll(() {
      final fontBytes = File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);

      final file = File('test/fixtures/khmer_golden_fixtures.json');
      expect(file.existsSync(), isTrue, reason: 'Golden fixture file must exist');
      final content = file.readAsStringSync();
      jsonCorpus = jsonDecode(content) as Map<String, dynamic>;
      fixtures = jsonCorpus['fixtures'] as List<dynamic>;
    });

    test('All 206 golden fixtures match HarfBuzz in glyph count, IDs, order, clusters, and full 2D metrics', () {
      int passed = 0;
      final failures = <String>[];

      for (final f in fixtures) {
        final id = f['id'] as String;
        final text = f['text'] as String;
        final expectedGlyphs = f['harfbuzz']['glyphs'] as List<dynamic>;

        final tracer = DiagnosticTraceLogger();
        final run = shaper.shapeText(text, tracer: tracer);

        bool matches = true;
        final failureReasons = <String>[];

        // 1. Glyph count check
        if (run.glyphs.length != expectedGlyphs.length) {
          matches = false;
          failureReasons.add(
            'Glyph count mismatch: actual ${run.glyphs.length} != expected ${expectedGlyphs.length}\n'
            '  Actual GIDs:   ${run.glyphs.map((g) => g.glyphId).toList()}\n'
            '  Expected GIDs: ${expectedGlyphs.map((g) => g['glyph_id']).toList()}',
          );
        } else {
          for (int i = 0; i < run.glyphs.length; i++) {
            final actual = run.glyphs[i];
            final expected = expectedGlyphs[i];

            // 2. Glyph ID & order check
            if (actual.glyphId != expected['glyph_id']) {
              matches = false;
              failureReasons.add(
                'Glyph $i ID mismatch: actual ${actual.glyphId} != expected ${expected['glyph_id']}',
              );
            }

            // 3. Cluster value check
            if (actual.cluster != expected['cluster']) {
              matches = false;
              failureReasons.add(
                'Glyph $i cluster mismatch: actual ${actual.cluster} != expected ${expected['cluster']}',
              );
            }

            // 4. xAdvance check
            if ((actual.xAdvance - (expected['x_advance'] as num).toDouble()).abs() > 0.001) {
              matches = false;
              failureReasons.add(
                'Glyph $i xAdvance mismatch: actual ${actual.xAdvance} != expected ${expected['x_advance']}',
              );
            }

            // 5. yAdvance, xOffset, yOffset check
            if (actual.yAdvance != (expected['y_advance'] as num).toDouble() ||
                actual.xOffset != (expected['x_offset'] as num).toDouble() ||
                actual.yOffset != (expected['y_offset'] as num).toDouble()) {
              matches = false;
              failureReasons.add('2D placement offset or yAdvance mismatch at glyph $i');
            }
          }
        }

        if (matches) {
          passed++;
        } else {
          failures.add('Fixture "$id" ("$text"):\n  ${failureReasons.join('\n  ')}');
        }
      }

      if (failures.isNotEmpty) {
        fail('Failures (${failures.length} / ${fixtures.length}):\n${failures.join('\n\n')}');
      }

      expect(
        passed,
        fixtures.length,
        reason: 'All ${fixtures.length} fixtures must match HarfBuzz across all 8 fields',
      );
    });

    test('Dedicated joiner and cluster regression tests', () {
      // 1. ក្ក (coeng_ka_ka)
      final r1 = shaper.shapeText('ក្ក');
      expect(r1.glyphs.map((g) => g.glyphId).toList(), [53, 295]);
      expect(r1.glyphs.map((g) => g.cluster).toList(), [0, 0]);
      expect(r1.glyphs.map((g) => g.xAdvance).toList(), [1221.0, 0.0]);

      // 2. ក្‍ក (joiner_coeng_zwj_ka)
      final r2 = shaper.shapeText('ក្\u200dក');
      expect(r2.glyphs.map((g) => g.glyphId).toList(), [53, 294, 259, 53]);
      expect(r2.glyphs.map((g) => g.cluster).toList(), [0, 0, 0, 3]);
      expect(r2.glyphs.map((g) => g.xAdvance).toList(), [1221.0, 0.0, 0.0, 1221.0]);

      // 3. ក‌េ (joiner_base_zwnj_vowel)
      final r3 = shaper.shapeText('ក\u200cេ');
      expect(r3.glyphs.map((g) => g.glyphId).toList(), [53, 259, 110, 272]);
      expect(r3.glyphs.map((g) => g.cluster).toList(), [0, 1, 1, 1]);
      expect(r3.glyphs.map((g) => g.xAdvance).toList(), [1221.0, 0.0, 610.0, 1217.0]);

      // 4. ឥ‍ក (joiner_indep_vowel_zwj)
      final r4 = shaper.shapeText('ឥ\u200dក');
      expect(r4.glyphs.map((g) => g.glyphId).toList(), [88, 259, 53]);
      expect(r4.glyphs.map((g) => g.cluster).toList(), [0, 0, 2]);
      expect(r4.glyphs.map((g) => g.xAdvance).toList(), [1221.0, 0.0, 1221.0]);

      // 5. ក្‌្ក (invalid_coeng_zwnj_coeng)
      final r5 = shaper.shapeText('ក្\u200c្ក');
      expect(r5.glyphs.map((g) => g.glyphId).toList(), [53, 294, 259, 272, 295]);
      expect(r5.glyphs.map((g) => g.cluster).toList(), [0, 0, 2, 2, 2]);
      expect(r5.glyphs.map((g) => g.xAdvance).toList(), [1221.0, 0.0, 0.0, 1217.0, 0.0]);
    });

    test('Stage-by-stage tracing captures intermediate layout transitions', () {
      final tracer = DiagnosticTraceLogger();
      final run = shaper.shapeText('សង្គ្រាម', tracer: tracer);

      expect(tracer.stages.containsKey('CMAP'), isTrue);
      expect(tracer.stages.containsKey('FEATURE blwf'), isTrue);
      expect(tracer.stages.containsKey('FEATURE pref'), isTrue);
      expect(tracer.stages.containsKey('FEATURE pstf'), isTrue);
      expect(tracer.stages.containsKey('FEATURE abvs'), isTrue);
      expect(tracer.stages.containsKey('FEATURE clig'), isTrue);
      expect(tracer.stages.containsKey('FINAL'), isTrue);
      expect(run.glyphs.length, 6);
    });
  });
}
