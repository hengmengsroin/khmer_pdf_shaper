import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/shaper/positioned_glyph.dart';
import 'package:khmer_pdf_shaper/src/shaper/shaped_run.dart';

void main() {
  group('Part 18: ShapedRun and PositionedGlyph Tests', () {
    test('PositionedGlyph retains full metric and cluster provenance', () {
      const glyph = PositionedGlyph(
        glyphId: 53,
        xAdvance: 1221.0,
        yAdvance: 0.0,
        xOffset: 0.0,
        yOffset: 0.0,
        cluster: 0,
        sourceStart: 0,
        sourceEnd: 1,
      );

      expect(glyph.glyphId, 53);
      expect(glyph.xAdvance, 1221.0);
      expect(glyph.yAdvance, 0.0);
      expect(glyph.xOffset, 0.0);
      expect(glyph.yOffset, 0.0);
      expect(glyph.cluster, 0);
      expect(glyph.sourceStart, 0);
      expect(glyph.sourceEnd, 1);
    });

    test('ShapedRun and ShapingCluster aggregate advances correctly', () {
      const g1 = PositionedGlyph(
        glyphId: 53,
        xAdvance: 1221.0,
        cluster: 0,
        sourceStart: 0,
        sourceEnd: 1,
      );
      const g2 = PositionedGlyph(
        glyphId: 295,
        xAdvance: 0.0,
        cluster: 0,
        sourceStart: 1,
        sourceEnd: 3,
      );

      final cluster = ShapingCluster(
        cluster: 0,
        glyphs: const [g1, g2],
        sourceStart: 0,
        sourceEnd: 3,
      );

      final run = ShapedRun(
        originalText: 'ក្ក',
        unitsPerEm: 2048,
        glyphs: const [g1, g2],
        clusters: [cluster],
      );

      expect(run.unitsPerEm, 2048);
      expect(run.totalAdvanceWidth, 1221.0);
      expect(cluster.totalAdvanceWidth, 1221.0);
      expect(run.clusters.length, 1);
    });
  });
}
