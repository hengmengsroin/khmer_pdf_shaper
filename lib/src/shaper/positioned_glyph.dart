/// Positioned glyph output from the font shaping engine.
class PositionedGlyph {
  /// OpenType glyph ID in the target font.
  final int glyphId;

  /// Horizontal advance width in integer font design units.
  final double xAdvance;

  /// Vertical advance in font design units (0.0 for horizontal layout).
  final double yAdvance;

  /// Horizontal glyph placement offset in font design units (0.0 for Battambang v1).
  final double xOffset;

  /// Vertical glyph placement offset in font design units (0.0 for Battambang v1).
  final double yOffset;

  /// Shaping cluster identifier (monotone non-decreasing).
  final int cluster;

  /// UTF-16 code unit start offset in the original source string.
  final int sourceStart;

  /// UTF-16 code unit end offset (exclusive) in the original source string.
  final int sourceEnd;

  const PositionedGlyph({
    required this.glyphId,
    required this.xAdvance,
    this.yAdvance = 0.0,
    this.xOffset = 0.0,
    this.yOffset = 0.0,
    required this.cluster,
    required this.sourceStart,
    required this.sourceEnd,
  });

  @override
  String toString() =>
      'PositionedGlyph(gid: $glyphId, adv: $xAdvance, cl: $cluster, src: $sourceStart..$sourceEnd)';
}
