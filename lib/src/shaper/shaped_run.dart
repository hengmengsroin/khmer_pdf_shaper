import 'positioned_glyph.dart';

/// Group of shaped glyphs belonging to a single shaping cluster.
class ShapingCluster {
  final int cluster;
  final List<PositionedGlyph> glyphs;
  final int sourceStart;
  final int sourceEnd;

  const ShapingCluster({
    required this.cluster,
    required this.glyphs,
    required this.sourceStart,
    required this.sourceEnd,
  });

  /// Total horizontal advance width of the cluster in font units.
  double get totalAdvanceWidth =>
      glyphs.fold(0.0, (sum, g) => sum + g.xAdvance);
}

/// Final output of the shaping pipeline representing a shaped text run.
class ShapedRun {
  /// Original input string.
  final String originalText;

  /// Font units per Em (2048 for Battambang-Regular).
  final int unitsPerEm;

  /// Positioned glyphs in visual order.
  final List<PositionedGlyph> glyphs;

  /// Clustered glyph groupings for line breaking and ToUnicode mapping.
  final List<ShapingCluster> clusters;

  ShapedRun({
    required this.originalText,
    required this.unitsPerEm,
    required this.glyphs,
    required this.clusters,
  });

  /// Total horizontal advance width of the entire run in font design units.
  double get totalAdvanceWidth =>
      glyphs.fold(0.0, (sum, g) => sum + g.xAdvance);

  @override
  String toString() =>
      'ShapedRun("${originalText.replaceAll('\n', '\\n')}", ${glyphs.length} glyphs, adv: $totalAdvanceWidth)';
}
