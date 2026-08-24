import 'package:pdf/pdf.dart';
import '../shaper/positioned_glyph.dart';
import '../shaper/shaped_run.dart';
import 'khmer_layout_token.dart';

/// Kind of visual run on a layout line.
enum KhmerVisualRunKind {
  /// Latin / Digits / Punctuation / Space run rendered via normal `PdfFont` drawing path.
  latin,

  /// Khmer script text run shaped via Battambang and rendered via `KhmerPdfFont.drawShapedRun`.
  khmer,
}

/// A contiguous visual run of a single script family on a line.
class KhmerLayoutVisualRun {
  /// Script kind (latin or khmer).
  final KhmerVisualRunKind kind;

  /// Text content of this visual run.
  final String text;

  /// Visual advance width in PDF points.
  final double width;

  /// Advance width in font design units.
  final double advanceFontUnits;

  /// ShapedRun for Khmer runs (null for Latin).
  final ShapedRun? shapedRun;

  /// Latin font used for measurement/painting (null for Khmer).
  final PdfFont? latinFont;

  /// UTF-16 start offset in original source string.
  final int sourceStart;

  /// UTF-16 end offset (exclusive) in original source string.
  final int sourceEnd;

  /// Clusters comprising this visual run.
  final List<KhmerLayoutCluster> clusters;

  const KhmerLayoutVisualRun({
    required this.kind,
    required this.text,
    required this.width,
    this.advanceFontUnits = 0.0,
    this.shapedRun,
    this.latinFont,
    required this.sourceStart,
    required this.sourceEnd,
    required this.clusters,
  });

  @override
  String toString() =>
      'KhmerLayoutVisualRun($kind, "$text", w: ${width.toStringAsFixed(2)}, src: $sourceStart..$sourceEnd)';
}

/// Atomic layout unit representing a shaped cluster, a Latin token, or a layout token.
class KhmerLayoutCluster {
  /// Token type (khmer, latin, space, nbsp, zwsp).
  final KhmerLayoutTokenType type;

  /// Optional underlying shaping cluster (present for shaped Khmer text).
  final ShapingCluster? shapedCluster;

  /// Positioned glyphs in visual order.
  final List<PositionedGlyph> glyphs;

  /// Advance width in integer font design units.
  final double advanceFontUnits;

  /// Layout width in PDF points: `advanceFontUnits * fontSize / unitsPerEm`.
  final double width;

  /// UTF-16 start offset in original source string.
  final int sourceStart;

  /// UTF-16 end offset (exclusive) in original source string.
  final int sourceEnd;

  /// Original text slice.
  final String text;

  /// Whether this cluster is whitespace (e.g. space or zwsp).
  final bool isWhitespace;

  /// Whether a line break is legally permitted after this cluster.
  final bool isBreakOpportunity;

  /// Whether this cluster occupies visible ink on the page.
  final bool isVisible;

  const KhmerLayoutCluster({
    required this.type,
    this.shapedCluster,
    required this.glyphs,
    required this.advanceFontUnits,
    required this.width,
    required this.sourceStart,
    required this.sourceEnd,
    required this.text,
    required this.isWhitespace,
    required this.isBreakOpportunity,
    required this.isVisible,
  });

  /// Factory for a shaped Khmer cluster.
  factory KhmerLayoutCluster.fromShapedCluster({
    required ShapingCluster cluster,
    required String originalText,
    required double fontSize,
    required int unitsPerEm,
    required int sourceOffset,
  }) {
    final adv = cluster.totalAdvanceWidth;
    final widthPts = adv * fontSize / unitsPerEm;
    final start = sourceOffset + cluster.sourceStart;
    final end = sourceOffset + cluster.sourceEnd;
    final clusterText =
        originalText.substring(cluster.sourceStart, cluster.sourceEnd);

    final adjustedGlyphs = cluster.glyphs.map((g) {
      return PositionedGlyph(
        glyphId: g.glyphId,
        xAdvance: g.xAdvance,
        yAdvance: g.yAdvance,
        xOffset: g.xOffset,
        yOffset: g.yOffset,
        cluster: g.cluster,
        sourceStart: sourceOffset + g.sourceStart,
        sourceEnd: sourceOffset + g.sourceEnd,
      );
    }).toList();

    return KhmerLayoutCluster(
      type: KhmerLayoutTokenType.khmer,
      shapedCluster: cluster,
      glyphs: adjustedGlyphs,
      advanceFontUnits: adv,
      width: widthPts,
      sourceStart: start,
      sourceEnd: end,
      text: clusterText,
      isWhitespace: false,
      isBreakOpportunity: false,
      isVisible: true,
    );
  }

  /// Factory for a Latin / non-Khmer text cluster.
  factory KhmerLayoutCluster.latin({
    required List<PositionedGlyph> glyphs,
    required String text,
    required double advanceFontUnits,
    required double fontSize,
    required int unitsPerEm,
    required int sourceStart,
    required int sourceEnd,
  }) {
    final widthPts = advanceFontUnits * fontSize / unitsPerEm;
    return KhmerLayoutCluster(
      type: KhmerLayoutTokenType.latin,
      shapedCluster: null,
      glyphs: glyphs,
      advanceFontUnits: advanceFontUnits,
      width: widthPts,
      sourceStart: sourceStart,
      sourceEnd: sourceEnd,
      text: text,
      isWhitespace: false,
      isBreakOpportunity: false,
      isVisible: true,
    );
  }

  /// Factory for U+0020 SPACE.
  factory KhmerLayoutCluster.space({
    required int spaceGlyphId,
    required double advanceFontUnits,
    required double fontSize,
    required int unitsPerEm,
    required int sourceStart,
    required int sourceEnd,
  }) {
    final widthPts = advanceFontUnits * fontSize / unitsPerEm;
    final glyph = PositionedGlyph(
      glyphId: spaceGlyphId,
      xAdvance: advanceFontUnits,
      cluster: 0,
      sourceStart: sourceStart,
      sourceEnd: sourceEnd,
    );
    return KhmerLayoutCluster(
      type: KhmerLayoutTokenType.space,
      glyphs: [glyph],
      advanceFontUnits: advanceFontUnits,
      width: widthPts,
      sourceStart: sourceStart,
      sourceEnd: sourceEnd,
      text: ' ',
      isWhitespace: true,
      isBreakOpportunity: true,
      isVisible: true,
    );
  }

  /// Factory for U+00A0 NO-BREAK SPACE (NBSP).
  factory KhmerLayoutCluster.nbsp({
    required int spaceGlyphId,
    required double advanceFontUnits,
    required double fontSize,
    required int unitsPerEm,
    required int sourceStart,
    required int sourceEnd,
  }) {
    final widthPts = advanceFontUnits * fontSize / unitsPerEm;
    final glyph = PositionedGlyph(
      glyphId: spaceGlyphId,
      xAdvance: advanceFontUnits,
      cluster: 0,
      sourceStart: sourceStart,
      sourceEnd: sourceEnd,
    );
    return KhmerLayoutCluster(
      type: KhmerLayoutTokenType.nbsp,
      glyphs: [glyph],
      advanceFontUnits: advanceFontUnits,
      width: widthPts,
      sourceStart: sourceStart,
      sourceEnd: sourceEnd,
      text: '\u00A0',
      isWhitespace: false,
      isBreakOpportunity: false,
      isVisible: true,
    );
  }

  /// Factory for U+200B ZERO WIDTH SPACE (ZWSP).
  factory KhmerLayoutCluster.zwsp({
    required int sourceStart,
    required int sourceEnd,
  }) {
    return KhmerLayoutCluster(
      type: KhmerLayoutTokenType.zwsp,
      glyphs: const [],
      advanceFontUnits: 0.0,
      width: 0.0,
      sourceStart: sourceStart,
      sourceEnd: sourceEnd,
      text: '\u200B',
      isWhitespace: true,
      isBreakOpportunity: true,
      isVisible: false,
    );
  }

  @override
  String toString() =>
      'KhmerLayoutCluster($type, "$text", w: ${width.toStringAsFixed(2)}, src: $sourceStart..$sourceEnd)';
}

/// A laid out line of text composed of sequential [KhmerLayoutCluster]s.
class KhmerLayoutLine {
  /// Ordered clusters in this line.
  final List<KhmerLayoutCluster> clusters;

  /// Visible width in PDF points (excluding trailing breakable whitespace).
  final double visualWidth;

  /// Full width in PDF points including all clusters.
  final double totalWidth;

  /// Line height in PDF points.
  final double height;

  /// Distance from top of line box to baseline.
  final double baseline;

  /// UTF-16 start offset in original source.
  final int sourceStart;

  /// UTF-16 end offset (exclusive) in original source.
  final int sourceEnd;

  const KhmerLayoutLine({
    required this.clusters,
    required this.visualWidth,
    required this.totalWidth,
    required this.height,
    required this.baseline,
    required this.sourceStart,
    required this.sourceEnd,
  });

  /// Groups clusters into contiguous [KhmerLayoutVisualRun]s separated by script kind.
  List<KhmerLayoutVisualRun> getVisualRuns(int unitsPerEm,
      {PdfFont? latinFont}) {
    final runs = <KhmerLayoutVisualRun>[];
    if (clusters.isEmpty) return runs;

    var currentClusters = <KhmerLayoutCluster>[];
    KhmerVisualRunKind? currentKind;

    void flushRun() {
      if (currentClusters.isEmpty || currentKind == null) return;
      final text = currentClusters.map((c) => c.text).join();
      final width = currentClusters.fold(0.0, (sum, c) => sum + c.width);
      final adv =
          currentClusters.fold(0.0, (sum, c) => sum + c.advanceFontUnits);
      final start = currentClusters.first.sourceStart;
      final end = currentClusters.last.sourceEnd;

      if (currentKind == KhmerVisualRunKind.khmer) {
        final lineTemp = KhmerLayoutLine(
          clusters: currentClusters,
          visualWidth: width,
          totalWidth: width,
          height: height,
          baseline: baseline,
          sourceStart: start,
          sourceEnd: end,
        );
        runs.add(KhmerLayoutVisualRun(
          kind: KhmerVisualRunKind.khmer,
          text: text,
          width: width,
          advanceFontUnits: adv,
          shapedRun: lineTemp.toShapedRun(unitsPerEm),
          sourceStart: start,
          sourceEnd: end,
          clusters: List.of(currentClusters),
        ));
      } else {
        runs.add(KhmerLayoutVisualRun(
          kind: KhmerVisualRunKind.latin,
          text: text,
          width: width,
          advanceFontUnits: adv,
          latinFont: latinFont,
          sourceStart: start,
          sourceEnd: end,
          clusters: List.of(currentClusters),
        ));
      }
      currentClusters = [];
    }

    for (final c in clusters) {
      if (!c.isVisible) continue; // Skip invisible ZWSP in visual runs

      final kind = (c.type == KhmerLayoutTokenType.khmer)
          ? KhmerVisualRunKind.khmer
          : KhmerVisualRunKind.latin;

      if (currentKind != null && currentKind != kind) {
        flushRun();
      }
      currentKind = kind;
      currentClusters.add(c);
    }
    flushRun();

    return runs;
  }

  /// Constructs a [ShapedRun] representation of all glyphs on this line
  /// for rendering via `KhmerPdfFont.drawShapedRun`.
  ShapedRun toShapedRun(int unitsPerEm) {
    final allGlyphs = <PositionedGlyph>[];
    final shapingClusters = <ShapingCluster>[];

    final buffer = StringBuffer();
    int lineOffset = 0;

    for (int i = 0; i < clusters.length; i++) {
      final c = clusters[i];
      final clusterText = c.text;
      buffer.write(clusterText);
      final clusterLen = clusterText.length;

      if (c.glyphs.isNotEmpty) {
        final lineGlyphs = c.glyphs.map((g) {
          final relStart = (g.sourceStart >= c.sourceStart)
              ? g.sourceStart - c.sourceStart
              : 0;
          final relEnd = (g.sourceEnd >= c.sourceStart)
              ? g.sourceEnd - c.sourceStart
              : clusterLen;

          return PositionedGlyph(
            glyphId: g.glyphId,
            xAdvance: g.xAdvance,
            yAdvance: g.yAdvance,
            xOffset: g.xOffset,
            yOffset: g.yOffset,
            cluster: i,
            sourceStart: lineOffset + relStart,
            sourceEnd: lineOffset + relEnd,
          );
        }).toList();

        allGlyphs.addAll(lineGlyphs);
        shapingClusters.add(ShapingCluster(
          cluster: i,
          glyphs: lineGlyphs,
          sourceStart: lineOffset,
          sourceEnd: lineOffset + clusterLen,
        ));
      }
      lineOffset += clusterLen;
    }

    return ShapedRun(
      originalText: buffer.toString(),
      unitsPerEm: unitsPerEm,
      glyphs: allGlyphs,
      clusters: shapingClusters,
    );
  }

  @override
  String toString() =>
      'KhmerLayoutLine(${clusters.length} clusters, visWidth: ${visualWidth.toStringAsFixed(2)}, totalWidth: ${totalWidth.toStringAsFixed(2)})';
}

/// Complete multi-line layout result.
class KhmerTextLayout {
  /// Ordered lines of text.
  final List<KhmerLayoutLine> lines;

  /// Layout width in PDF points (maximum visual width across all lines).
  final double width;

  /// Total layout height in PDF points (`lines.length * lineHeight`).
  final double height;

  /// Font size used during layout.
  final double fontSize;

  /// Line height in PDF points.
  final double lineHeight;

  /// Natural line height derived directly from font vertical metrics.
  final double naturalLineHeight;

  /// Font ascent in PDF points.
  final double ascent;

  /// Font descent in PDF points (positive magnitude).
  final double descent;

  /// Vertical offset from line top to text baseline in PDF points.
  final double baselineOffset;

  const KhmerTextLayout({
    required this.lines,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.lineHeight,
    required this.naturalLineHeight,
    required this.ascent,
    required this.descent,
    required this.baselineOffset,
  });

  @override
  String toString() =>
      'KhmerTextLayout(${lines.length} lines, size: ${width.toStringAsFixed(2)}x${height.toStringAsFixed(2)}, fontSize: $fontSize, lineHeight: ${lineHeight.toStringAsFixed(2)})';
}
