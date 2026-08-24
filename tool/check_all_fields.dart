// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  final fontBytes = File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
  final shaper = BattambangShaper.fromBytes(fontBytes);

  final file = File('test/fixtures/khmer_golden_fixtures.json');
  final jsonCorpus = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final fixtures = jsonCorpus['fixtures'] as List<dynamic>;

  int matchCount = 0;
  final mismatches = <String>[];

  for (final f in fixtures) {
    final id = f['id'] as String;
    final text = f['text'] as String;
    final expectedGlyphs = f['harfbuzz']['glyphs'] as List<dynamic>;

    final run = shaper.shapeText(text);

    bool match = true;
    if (run.glyphs.length != expectedGlyphs.length) {
      match = false;
      mismatches.add('$id: length mismatch (${run.glyphs.length} vs ${expectedGlyphs.length})');
    } else {
      for (int i = 0; i < run.glyphs.length; i++) {
        final actual = run.glyphs[i];
        final expected = expectedGlyphs[i];

        if (actual.glyphId != expected['glyph_id'] ||
            actual.cluster != expected['cluster'] ||
            (actual.xAdvance - (expected['x_advance'] as num).toDouble()).abs() > 0.001 ||
            actual.yAdvance != (expected['y_advance'] as num).toDouble() ||
            actual.xOffset != (expected['x_offset'] as num).toDouble() ||
            actual.yOffset != (expected['y_offset'] as num).toDouble()) {
          match = false;
          final actualClusters = run.glyphs.map((g) => g.cluster).toList();
          final expectedClusters = expectedGlyphs.map((g) => g['cluster']).toList();
          mismatches.add('$id ("$text"): actual clusters $actualClusters vs expected $expectedClusters');
          break;
        }
      }
    }

    if (match) {
      matchCount++;
    }
  }

  print('Matched all fields: $matchCount / ${fixtures.length}');
  print('Mismatches (${mismatches.length}):');
  for (final m in mismatches) {
    print('  - $m');
  }
}
