import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/font/font_binary_validator.dart';

void main() {
  group('Khmer Golden Fixture Corpus Validation', () {
    late Map<String, dynamic> jsonCorpus;
    late List<dynamic> fixtures;

    setUpAll(() {
      final file = File('test/fixtures/khmer_golden_fixtures.json');
      expect(file.existsSync(), isTrue,
          reason: 'Golden fixture file must exist');
      final content = file.readAsStringSync();
      jsonCorpus = jsonDecode(content) as Map<String, dynamic>;
      fixtures = jsonCorpus['fixtures'] as List<dynamic>;
    });

    test(
        'Metadata header is populated with HarfBuzz oracle details and exact provenance',
        () {
      final oracle = jsonCorpus['oracle'] as Map<String, dynamic>;
      expect(oracle['harfbuzz_version'], 'hb-shape (HarfBuzz) 14.2.1');
      expect(oracle['font_name'], 'Battambang-Regular');
      expect(oracle['font_sha256'],
          'c7d867c7d4e8371f23678bd12cd1700cab1e4e37ec2860eb439766142b240bd9');
      expect(oracle['units_per_em'], 2048);
      expect(oracle['fixture_count'], 206);
      expect(fixtures.length, 206);

      final shapingConfig = oracle['shaping_config'] as Map<String, dynamic>;
      expect(shapingConfig['script'], 'khmr');
      expect(shapingConfig['direction'], 'ltr');
      expect(shapingConfig['language'], 'km');
      expect(shapingConfig['features'], contains('pref'));
      expect(shapingConfig['features'], contains('blwf'));
    });

    test(
        'Bundled Battambang font SHA256 exactly matches golden oracle font SHA256',
        () {
      final fontBytes =
          File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
      final oracle = jsonCorpus['oracle'] as Map<String, dynamic>;
      final expectedSha = oracle['font_sha256'] as String;

      expect(FontBinaryValidator.battambangRegularSha256, equals(expectedSha));
      expect(() => FontBinaryValidator.verifySupportedFont(fontBytes),
          returnsNormally);
    });

    test('All required categories are represented', () {
      final categories = fixtures.map((f) => f['category'] as String).toSet();
      final requiredCategories = {
        'BASE',
        'VOWEL_PRE',
        'VOWEL_ABOVE',
        'VOWEL_BELOW',
        'VOWEL_POST',
        'VOWEL_SPLIT',
        'COENG_BASIC',
        'COENG_RO',
        'COENG_MULTIPLE',
        'REGISTER_SHIFTER',
        'ROBAT',
        'ABOVE_MARK',
        'MULTIPLE_MARKS',
        'BROKEN_CLUSTER',
        'ZWJ_ZWNJ',
        'KHMER_DIGITS',
        'PUNCTUATION',
        'REAL_WORD',
        'REAL_SENTENCE',
        'MIXED_SCRIPT',
      };

      for (final cat in requiredCategories) {
        expect(categories.contains(cat), isTrue,
            reason: 'Category $cat must be present');
      }
    });

    test('Every fixture has valid non-empty glyph run with valid metrics', () {
      for (final f in fixtures) {
        final id = f['id'] as String;
        final glyphs = f['harfbuzz']['glyphs'] as List<dynamic>;
        expect(glyphs, isNotEmpty,
            reason: 'Fixture $id must have shaped glyphs');

        for (final g in glyphs) {
          final gid = g['glyph_id'] as int;
          final cluster = g['cluster'] as int;
          final xAdv = (g['x_advance'] as num).toDouble();
          final yAdv = (g['y_advance'] as num).toDouble();
          final xOff = (g['x_offset'] as num).toDouble();
          final yOff = (g['y_offset'] as num).toDouble();

          expect(gid, greaterThanOrEqualTo(0),
              reason: 'Glyph ID in $id must be non-negative');
          expect(cluster, greaterThanOrEqualTo(0),
              reason: 'Cluster in $id must be non-negative');
          expect(xAdv, greaterThanOrEqualTo(0.0),
              reason: 'X-advance in $id must be non-negative');
          expect(yAdv, 0.0, reason: 'Y-advance in Battambang must be 0');
          expect(xOff, 0.0, reason: 'X-offset in Battambang must be 0');
          expect(yOff, 0.0, reason: 'Y-offset in Battambang must be 0');
        }
      }
    });
  });
}
