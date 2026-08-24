import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/gsub/coverage_table.dart';
import 'package:khmer_pdf_shaper/src/gsub/gsub_tables.dart';

void main() {
  group('Part 7: GSUB Type 1 SingleSubst Tests', () {
    test('Format 1 delta substitution preserves glyph provenance and cluster',
        () {
      final cov = CoverageFormat1([10, 11, 12]);
      final subst = SingleSubst.format1(coverage: cov, deltaGlyphId: 100);

      final buffer = [
        ShapingGlyph(
            glyphId: 10,
            cluster: 0,
            sourceStart: 0,
            sourceEnd: 1,
            featureMask: 1),
        ShapingGlyph(
            glyphId: 15,
            cluster: 1,
            sourceStart: 1,
            sourceEnd: 2,
            featureMask: 2),
      ];

      final applied = subst.apply(buffer, 0, (idx, buf, pos) => false);
      expect(applied, isTrue);
      expect(buffer[0].glyphId, 110);
      expect(buffer[0].cluster, 0);
      expect(buffer[0].sourceStart, 0);
      expect(buffer[0].sourceEnd, 1);
      expect(buffer[0].featureMask, 1);

      final notApplied = subst.apply(buffer, 1, (idx, buf, pos) => false);
      expect(notApplied, isFalse);
      expect(buffer[1].glyphId, 15);
    });

    test('Format 2 array substitution maps coverage index to target glyph ID',
        () {
      final cov = CoverageFormat1([20, 30]);
      final subst =
          SingleSubst.format2(coverage: cov, substituteGlyphIds: [200, 300]);

      final buffer = [
        ShapingGlyph(glyphId: 30, cluster: 5, sourceStart: 4, sourceEnd: 6),
      ];

      final applied = subst.apply(buffer, 0, (idx, buf, pos) => false);
      expect(applied, isTrue);
      expect(buffer[0].glyphId, 300);
      expect(buffer[0].cluster, 5);
    });
  });
}
