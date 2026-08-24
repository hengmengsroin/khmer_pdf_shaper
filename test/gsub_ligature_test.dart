import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_pdf_shaper/src/gsub/coverage_table.dart';
import 'package:tamil_pdf_shaper/src/gsub/gsub_tables.dart';

void main() {
  group('Part 8: GSUB Type 4 LigatureSubst Tests', () {
    test('Substitutes 2-glyph sequence and combines cluster and source range', () {
      final cov = CoverageFormat1([10]);
      final ligSet = [
        Ligature(ligGlyphId: 99, componentGlyphIds: [20]),
      ];
      final subst = LigatureSubst(coverage: cov, ligatureSets: [ligSet]);

      final buffer = [
        ShapingGlyph(glyphId: 10, cluster: 0, sourceStart: 0, sourceEnd: 1, featureMask: 1),
        ShapingGlyph(glyphId: 20, cluster: 0, sourceStart: 1, sourceEnd: 2, featureMask: 2),
        ShapingGlyph(glyphId: 30, cluster: 2, sourceStart: 2, sourceEnd: 3, featureMask: 4),
      ];

      final applied = subst.apply(buffer, 0, (idx, buf, pos) => false);
      expect(applied, isTrue);
      expect(buffer.length, 2);
      expect(buffer[0].glyphId, 99);
      expect(buffer[0].cluster, 0);
      expect(buffer[0].sourceStart, 0);
      expect(buffer[0].sourceEnd, 2);
      expect(buffer[0].featureMask, 3); // 1 | 2
      expect(buffer[1].glyphId, 30);
    });

    test('Respects ligature order and priority', () {
      final cov = CoverageFormat1([10]);
      final ligSet = [
        Ligature(ligGlyphId: 999, componentGlyphIds: [20, 30]), // 3-glyph match first
        Ligature(ligGlyphId: 99, componentGlyphIds: [20]),       // 2-glyph fallback
      ];
      final subst = LigatureSubst(coverage: cov, ligatureSets: [ligSet]);

      final buffer = [
        ShapingGlyph(glyphId: 10, cluster: 0, sourceStart: 0, sourceEnd: 1),
        ShapingGlyph(glyphId: 20, cluster: 0, sourceStart: 1, sourceEnd: 2),
        ShapingGlyph(glyphId: 30, cluster: 0, sourceStart: 2, sourceEnd: 3),
      ];

      final applied = subst.apply(buffer, 0, (idx, buf, pos) => false);
      expect(applied, isTrue);
      expect(buffer.length, 1);
      expect(buffer[0].glyphId, 999);
      expect(buffer[0].sourceStart, 0);
      expect(buffer[0].sourceEnd, 3);
    });
  });
}
