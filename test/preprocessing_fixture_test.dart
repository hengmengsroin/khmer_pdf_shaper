import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/khmer/khmer_internal.dart';

void main() {
  group('Part 12: Preprocessing Golden Fixtures Validation', () {
    late Map<String, dynamic> jsonCorpus;
    late List<dynamic> fixtures;

    setUpAll(() {
      final file = File('test/fixtures/khmer_preprocessing_fixtures.json');
      expect(file.existsSync(), isTrue,
          reason: 'Preprocessing fixture file must exist');
      final content = file.readAsStringSync();
      jsonCorpus = jsonDecode(content) as Map<String, dynamic>;
      fixtures = jsonCorpus['fixtures'] as List<dynamic>;
    });

    test('Metadata header is populated with algorithm-derived details', () {
      final oracle = jsonCorpus['oracle'] as Map<String, dynamic>;
      expect(oracle['generator'], isNotEmpty);
      expect(oracle['fixture_count'], 206);
      expect(oracle['derivation_type'], contains('algorithm-derived'));
    });

    test('All 206 fixtures reproduce expected preprocessing results', () {
      for (final f in fixtures) {
        final id = f['id'] as String;
        final text = f['text'] as String;
        final expectedNorm = f['normalized'] as List<dynamic>;
        final expectedSyls = f['syllables'] as List<dynamic>;
        final expectedReordered = f['reordered'] as List<dynamic>;

        final run = KhmerPreprocessor.preprocess(text);

        // Verify normalized count & codepoints
        expect(run.normalizedChars.length, expectedNorm.length,
            reason: 'Fixture $id normalized length mismatch');
        for (int i = 0; i < run.normalizedChars.length; i++) {
          expect(run.normalizedChars[i].codePoint, expectedNorm[i]['cp'],
              reason: 'Fixture $id normalized codepoint $i mismatch');
          expect(run.normalizedChars[i].sourceStart, expectedNorm[i]['start']);
          expect(run.normalizedChars[i].sourceEnd, expectedNorm[i]['end']);
        }

        // Verify syllables
        expect(run.syllables.length, expectedSyls.length,
            reason: 'Fixture $id syllables length mismatch');
        for (int i = 0; i < run.syllables.length; i++) {
          expect(run.syllables[i].type.name, expectedSyls[i]['type'],
              reason: 'Fixture $id syllable $i type mismatch');
          expect(run.syllables[i].start, expectedSyls[i]['start']);
          expect(run.syllables[i].end, expectedSyls[i]['end']);
        }

        // Verify reordered characters & cluster monotone non-decreasing
        expect(run.reorderedChars.length, expectedReordered.length,
            reason: 'Fixture $id reordered length mismatch');

        int lastCluster = -1;
        for (int i = 0; i < run.reorderedChars.length; i++) {
          final c = run.reorderedChars[i];
          final exp = expectedReordered[i];

          expect(c.codePoint, exp['cp'],
              reason: 'Fixture $id reordered codepoint $i mismatch');
          expect(c.sourceStart, exp['start'],
              reason: 'Fixture $id reordered sourceStart $i mismatch');
          expect(c.sourceEnd, exp['end'],
              reason: 'Fixture $id reordered sourceEnd $i mismatch');
          expect(c.cluster, exp['cluster'],
              reason: 'Fixture $id reordered cluster $i mismatch');

          // Cluster monotonicity (monotone non-decreasing)
          expect(c.cluster, greaterThanOrEqualTo(lastCluster),
              reason:
                  'Fixture $id cluster values must be monotone non-decreasing');
          lastCluster = c.cluster;

          expect(c.hasFeature(KhmerFeature.pref), exp['pref']);
          expect(c.hasFeature(KhmerFeature.blwf), exp['blwf']);
          expect(c.hasFeature(KhmerFeature.abvf), exp['abvf']);
          expect(c.hasFeature(KhmerFeature.pstf), exp['pstf']);
          expect(c.hasFeature(KhmerFeature.cfar), exp['cfar']);
        }
      }
    });
  });
}
