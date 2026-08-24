import 'dart:math' as math;
import 'dart:typed_data';
import '../font/cmap_table.dart';
import '../font/font_binary_validator.dart';
import '../font/metrics_table.dart';
import '../font/opentype_reader.dart';
import '../gsub/gsub_evaluator.dart';
import '../gsub/gsub_tables.dart';
import '../khmer/khmer_preprocessor.dart';
import 'positioned_glyph.dart';
import 'shaped_run.dart';

/// Prototype OpenType GSUB shaper locked to the exact bundled Battambang-Regular.ttf artifact.
class BattambangShaper {
  final OpenTypeFont font;
  final CmapTable cmap;
  final MetricsTable metrics;
  final GsubTable gsub;
  final int spaceGlyphId;

  BattambangShaper._({
    required this.font,
    required this.cmap,
    required this.metrics,
    required this.gsub,
    required this.spaceGlyphId,
  });

  /// Creates and initializes a [BattambangShaper] from [fontBytes].
  /// Validates font binary hash before parsing.
  factory BattambangShaper.fromBytes(Uint8List fontBytes) {
    // 1. Verify font contract
    FontBinaryValidator.verifySupportedFont(fontBytes);

    // 2. Parse OpenType table directory
    final font = OpenTypeFont.parse(fontBytes);

    // 3. Parse cmap
    final cmap = CmapTable.parse(font.getTableReader('cmap'));

    // 4. Parse metrics (head, hhea, maxp, hmtx)
    final metrics = MetricsTable.parse(
      headReader: font.getTableReader('head'),
      hheaReader: font.getTableReader('hhea'),
      maxpReader: font.getTableReader('maxp'),
      hmtxReader: font.getTableReader('hmtx'),
    );

    // 5. Parse GSUB
    final gsub = GsubTable.parse(font.getTableReader('GSUB'));

    // 6. Resolve space glyph ID for default ignorable fallback
    final spaceGid = cmap.glyphIdForCodePoint(0x0020);

    return BattambangShaper._(
      font: font,
      cmap: cmap,
      metrics: metrics,
      gsub: gsub,
      spaceGlyphId: spaceGid != 0 ? spaceGid : 259,
    );
  }

  /// Shapes a [PreprocessedKhmerRun] from Phase 2 into a [ShapedRun].
  ShapedRun shape(PreprocessedKhmerRun run, {GsubTraceLogger? tracer}) {
    // 1. Map reordered characters to initial glyph IDs via cmap
    final buffer = <ShapingGlyph>[];
    for (final char in run.reorderedChars) {
      final cp = char.codePoint;
      final isIgnorable =
          (cp == 0x200C || cp == 0x200D || cp == 0x200B || cp == 0xFEFF);
      final initialGid = cmap.glyphIdForCodePoint(cp);

      buffer.add(ShapingGlyph(
        glyphId: initialGid,
        cluster: char.cluster,
        sourceStart: char.sourceStart,
        sourceEnd: char.sourceEnd,
        featureMask: char.featureMask,
        isSynthetic: char.isSynthetic,
        isDefaultIgnorable: isIgnorable,
      ));
    }

    // 2. Evaluate GSUB layout substitutions
    gsub.evaluate(buffer, tracer: tracer);

    // 3. Post-shaping & metrics resolution
    final positionedGlyphs = <PositionedGlyph>[];
    for (final glyph in buffer) {
      int finalGid = glyph.glyphId;
      double advance;

      if (glyph.isDefaultIgnorable && finalGid == 0) {
        finalGid = spaceGlyphId;
        advance = 0.0;
      } else {
        advance = metrics.advanceWidthForGlyph(finalGid).toDouble();
      }

      positionedGlyphs.add(PositionedGlyph(
        glyphId: finalGid,
        xAdvance: advance,
        yAdvance: 0.0,
        xOffset: 0.0,
        yOffset: 0.0,
        cluster: glyph.cluster,
        sourceStart: glyph.sourceStart,
        sourceEnd: glyph.sourceEnd,
      ));
    }

    // 4. Group glyphs into clusters
    final clusterMap = <int, List<PositionedGlyph>>{};
    for (final g in positionedGlyphs) {
      clusterMap.putIfAbsent(g.cluster, () => []).add(g);
    }

    final clusters = <ShapingCluster>[];
    for (final entry in clusterMap.entries) {
      final clGlyphs = entry.value;
      int minStart = clGlyphs[0].sourceStart;
      int maxEnd = clGlyphs[0].sourceEnd;
      for (final g in clGlyphs) {
        minStart = math.min(minStart, g.sourceStart);
        maxEnd = math.max(maxEnd, g.sourceEnd);
      }
      clusters.add(ShapingCluster(
        cluster: entry.key,
        glyphs: clGlyphs,
        sourceStart: minStart,
        sourceEnd: maxEnd,
      ));
    }

    return ShapedRun(
      originalText: run.originalText,
      unitsPerEm: metrics.unitsPerEm,
      glyphs: positionedGlyphs,
      clusters: clusters,
    );
  }

  /// Convenience method: preprocesses Unicode [text] and shapes with Battambang GSUB.
  ShapedRun shapeText(String text, {GsubTraceLogger? tracer}) {
    final preprocessed = KhmerPreprocessor.preprocess(text);
    return shape(preprocessed, tracer: tracer);
  }
}
