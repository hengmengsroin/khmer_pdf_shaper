import '../shaper/battambang_shaper.dart';
import '../shaper/positioned_glyph.dart';
import 'khmer_layout_model.dart';
import 'khmer_layout_token.dart';
import 'khmer_line_metrics.dart';
import 'khmer_run_segmenter.dart';

/// Cluster-safe line breaking and layout engine for Khmer and mixed text.
class KhmerLineBreaker {
  final KhmerLineMetrics lineMetrics;

  const KhmerLineBreaker({
    this.lineMetrics = const KhmerLineMetrics(),
  });

  /// Computes a [KhmerTextLayout] for [text] at [fontSize] constrained to [maxWidth].
  KhmerTextLayout layout({
    required String text,
    required BattambangShaper shaper,
    required double fontSize,
    double maxWidth = double.infinity,
    double? lineHeightFactor,
  }) {
    final unitsPerEm = shaper.metrics.unitsPerEm;
    final naturalLineHeight = lineMetrics.calculateNaturalLineHeight(fontSize);
    final lineHeight = lineMetrics.calculateLineHeight(fontSize, lineHeightFactor);
    final ascent = lineMetrics.calculateAscent(fontSize);
    final descent = lineMetrics.calculateDescent(fontSize);
    final baselineOffset = lineMetrics.calculateBaselineOffset(fontSize, lineHeightFactor);

    if (text.isEmpty) {
      return KhmerTextLayout(
        lines: const [],
        width: 0.0,
        height: 0.0,
        fontSize: fontSize,
        lineHeight: lineHeight,
        naturalLineHeight: naturalLineHeight,
        ascent: ascent,
        descent: descent,
        baselineOffset: baselineOffset,
      );
    }

    final paragraphs = KhmerRunSegmenter.splitParagraphs(text);
    final allLines = <KhmerLayoutLine>[];
    int currentSourceOffset = 0;

    for (int pIndex = 0; pIndex < paragraphs.length; pIndex++) {
      final paragraph = paragraphs[pIndex];
      final paragraphTokens = KhmerRunSegmenter.segmentParagraph(
        paragraph,
        currentSourceOffset,
      );

      // Handle empty paragraphs (e.g. from consecutive newlines "\n\n")
      if (paragraphTokens.isEmpty) {
        allLines.add(KhmerLayoutLine(
          clusters: const [],
          visualWidth: 0.0,
          totalWidth: 0.0,
          height: lineHeight,
          baseline: baselineOffset,
          sourceStart: currentSourceOffset,
          sourceEnd: currentSourceOffset,
        ));
        // Account for the newline character in source offset
        currentSourceOffset += 1;
        continue;
      }

      // Convert tokens to layout clusters
      final paragraphClusters = <KhmerLayoutCluster>[];
      for (final token in paragraphTokens) {
        switch (token.type) {
          case KhmerLayoutTokenType.khmer:
            final shapedRun = shaper.shapeText(token.text);
            for (final cluster in shapedRun.clusters) {
              paragraphClusters.add(KhmerLayoutCluster.fromShapedCluster(
                cluster: cluster,
                originalText: token.text,
                fontSize: fontSize,
                unitsPerEm: unitsPerEm,
                sourceOffset: token.sourceStart,
              ));
            }
            break;

          case KhmerLayoutTokenType.latin:
            final glyphs = <PositionedGlyph>[];
            double totalAdv = 0.0;
            final runes = token.text.runes.toList();
            int charOffset = token.sourceStart;

            for (final cp in runes) {
              final gid = shaper.cmap.glyphIdForCodePoint(cp);
              final adv = shaper.metrics.advanceWidthForGlyph(gid).toDouble();
              final charLen = cp > 0xFFFF ? 2 : 1;
              totalAdv += adv;

              glyphs.add(PositionedGlyph(
                glyphId: gid,
                xAdvance: adv,
                cluster: 0,
                sourceStart: charOffset,
                sourceEnd: charOffset + charLen,
              ));
              charOffset += charLen;
            }

            paragraphClusters.add(KhmerLayoutCluster.latin(
              glyphs: glyphs,
              text: token.text,
              advanceFontUnits: totalAdv,
              fontSize: fontSize,
              unitsPerEm: unitsPerEm,
              sourceStart: token.sourceStart,
              sourceEnd: token.sourceEnd,
            ));
            break;

          case KhmerLayoutTokenType.space:
            final spaceGid = shaper.spaceGlyphId;
            final adv = shaper.metrics.advanceWidthForGlyph(spaceGid).toDouble();
            paragraphClusters.add(KhmerLayoutCluster.space(
              spaceGlyphId: spaceGid,
              advanceFontUnits: adv,
              fontSize: fontSize,
              unitsPerEm: unitsPerEm,
              sourceStart: token.sourceStart,
              sourceEnd: token.sourceEnd,
            ));
            break;

          case KhmerLayoutTokenType.nbsp:
            final nbspGid = shaper.cmap.glyphIdForCodePoint(0x00A0);
            final effectiveGid = (nbspGid != 0) ? nbspGid : shaper.spaceGlyphId;
            final adv = shaper.metrics.advanceWidthForGlyph(effectiveGid).toDouble();
            paragraphClusters.add(KhmerLayoutCluster.nbsp(
              spaceGlyphId: effectiveGid,
              advanceFontUnits: adv,
              fontSize: fontSize,
              unitsPerEm: unitsPerEm,
              sourceStart: token.sourceStart,
              sourceEnd: token.sourceEnd,
            ));
            break;

          case KhmerLayoutTokenType.zwsp:
            paragraphClusters.add(KhmerLayoutCluster.zwsp(
              sourceStart: token.sourceStart,
              sourceEnd: token.sourceEnd,
            ));
            break;
        }
      }

      // Break paragraph clusters into lines using cluster-safe wrapping
      final wrappedLines = _wrapParagraphClusters(
        paragraphClusters,
        maxWidth: maxWidth,
        lineHeight: lineHeight,
        baselineOffset: baselineOffset,
      );
      allLines.addAll(wrappedLines);

      // Account for paragraph length plus newline separator
      currentSourceOffset += paragraph.length + 1;
    }

    double maxVisualWidth = 0.0;
    for (final line in allLines) {
      if (line.visualWidth > maxVisualWidth) {
        maxVisualWidth = line.visualWidth;
      }
    }

    return KhmerTextLayout(
      lines: allLines,
      width: maxVisualWidth,
      height: allLines.length * lineHeight,
      fontSize: fontSize,
      lineHeight: lineHeight,
      naturalLineHeight: naturalLineHeight,
      ascent: ascent,
      descent: descent,
      baselineOffset: baselineOffset,
    );
  }

  /// Wraps a single paragraph's clusters into lines.
  List<KhmerLayoutLine> _wrapParagraphClusters(
    List<KhmerLayoutCluster> clusters, {
    required double maxWidth,
    required double lineHeight,
    required double baselineOffset,
  }) {
    if (clusters.isEmpty) {
      return const [];
    }

    if (!maxWidth.isFinite) {
      // Unconstrained width -> single line
      return [_createLine(clusters, lineHeight, baselineOffset)];
    }

    final lines = <KhmerLayoutLine>[];
    var currentLineClusters = <KhmerLayoutCluster>[];
    double currentLineWidth = 0.0;
    int lastBreakOpportunityIndex = -1;

    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];

      if (currentLineClusters.isNotEmpty &&
          (currentLineWidth + cluster.width > maxWidth)) {
        if (lastBreakOpportunityIndex >= 0) {
          // 1. Break at last whitespace opportunity
          final lineItems = currentLineClusters.sublist(
            0,
            lastBreakOpportunityIndex + 1,
          );
          final remaining = currentLineClusters.sublist(
            lastBreakOpportunityIndex + 1,
          );

          lines.add(_createLine(lineItems, lineHeight, baselineOffset));

          currentLineClusters = [...remaining, cluster];
          currentLineWidth = _calculateTotalWidth(currentLineClusters);
          lastBreakOpportunityIndex = _findLastBreakOpportunity(currentLineClusters);
          continue;
        } else {
          // 2. Cluster-safe fallback wrapping: break between adjacent shaping clusters
          lines.add(_createLine(currentLineClusters, lineHeight, baselineOffset));
          currentLineClusters = [cluster];
          currentLineWidth = cluster.width;
          lastBreakOpportunityIndex = cluster.isBreakOpportunity ? 0 : -1;
          continue;
        }
      }

      currentLineClusters.add(cluster);
      currentLineWidth += cluster.width;
      if (cluster.isBreakOpportunity) {
        lastBreakOpportunityIndex = currentLineClusters.length - 1;
      }
    }

    if (currentLineClusters.isNotEmpty) {
      lines.add(_createLine(currentLineClusters, lineHeight, baselineOffset));
    }

    return lines;
  }

  static double _calculateTotalWidth(List<KhmerLayoutCluster> clusters) {
    return clusters.fold(0.0, (sum, c) => sum + c.width);
  }

  static int _findLastBreakOpportunity(List<KhmerLayoutCluster> clusters) {
    for (int i = clusters.length - 1; i >= 0; i--) {
      if (clusters[i].isBreakOpportunity) {
        return i;
      }
    }
    return -1;
  }

  static KhmerLayoutLine _createLine(
    List<KhmerLayoutCluster> clusters,
    double lineHeight,
    double baselineOffset,
  ) {
    if (clusters.isEmpty) {
      return KhmerLayoutLine(
        clusters: const [],
        visualWidth: 0.0,
        totalWidth: 0.0,
        height: lineHeight,
        baseline: baselineOffset,
        sourceStart: 0,
        sourceEnd: 0,
      );
    }

    double totalWidth = 0.0;
    for (final c in clusters) {
      totalWidth += c.width;
    }

    // Trailing whitespace is excluded from visual width
    int lastVisibleIndex = clusters.length - 1;
    while (lastVisibleIndex >= 0 && clusters[lastVisibleIndex].isWhitespace) {
      lastVisibleIndex--;
    }

    double visualWidth = 0.0;
    if (lastVisibleIndex >= 0) {
      for (int i = 0; i <= lastVisibleIndex; i++) {
        visualWidth += clusters[i].width;
      }
    }

    return KhmerLayoutLine(
      clusters: clusters,
      visualWidth: visualWidth,
      totalWidth: totalWidth,
      height: lineHeight,
      baseline: baselineOffset,
      sourceStart: clusters.first.sourceStart,
      sourceEnd: clusters.last.sourceEnd,
    );
  }
}
