import 'package:pdf/pdf.dart';
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
    PdfFont? latinFont,
    double maxWidth = double.infinity,
    double? lineHeightFactor,
  }) {
    if (fontSize <= 0 || !fontSize.isFinite) {
      throw ArgumentError.value(
          fontSize, 'fontSize', 'Font size must be positive and finite.');
    }
    if (lineHeightFactor != null &&
        (lineHeightFactor <= 0 || !lineHeightFactor.isFinite)) {
      throw ArgumentError.value(
        lineHeightFactor,
        'lineHeightFactor',
        'Line height factor must be positive and finite.',
      );
    }

    final unitsPerEm = shaper.metrics.unitsPerEm;
    final naturalLineHeight =
        lineMetrics.calculateMixedNaturalLineHeight(fontSize, latinFont);
    final lineHeight = lineMetrics.calculateMixedLineHeight(
      fontSize,
      latinFont: latinFont,
      lineHeightFactor: lineHeightFactor,
    );
    final ascent = lineMetrics.calculateLineAscent(fontSize, latinFont);
    final descent = lineMetrics.calculateLineDescent(fontSize, latinFont);
    final baselineOffset = lineMetrics.calculateMixedBaselineOffset(
      fontSize,
      latinFont: latinFont,
      lineHeightFactor: lineHeightFactor,
    );

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
            if (latinFont != null) {
              final supportedBuffer = StringBuffer();
              double totalWidthPts = 0.0;
              for (final cp in token.text.runes) {
                if (latinFont.isRuneSupported(cp)) {
                  supportedBuffer.writeCharCode(cp);
                  final metrics = latinFont.glyphMetrics(cp);
                  totalWidthPts += metrics.advanceWidth * fontSize;
                } else {
                  supportedBuffer.write('?');
                  final fallbackCp =
                      latinFont.isRuneSupported(0x3F) ? 0x3F : 0x20;
                  final metrics = latinFont.glyphMetrics(fallbackCp);
                  totalWidthPts += metrics.advanceWidth * fontSize;
                }
              }
              final advUnits = totalWidthPts * unitsPerEm / fontSize;

              paragraphClusters.add(KhmerLayoutCluster.latin(
                glyphs: const [],
                text: supportedBuffer.toString(),
                advanceFontUnits: advUnits,
                fontSize: fontSize,
                unitsPerEm: unitsPerEm,
                sourceStart: token.sourceStart,
                sourceEnd: token.sourceEnd,
              ));
            } else {
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
            }
            break;

          case KhmerLayoutTokenType.space:
            double advUnits;
            if (latinFont != null) {
              final spaceMetrics = latinFont.stringMetrics(' ');
              final widthPts = spaceMetrics.advanceWidth * fontSize;
              advUnits = widthPts * unitsPerEm / fontSize;
            } else {
              advUnits = shaper.metrics
                  .advanceWidthForGlyph(shaper.spaceGlyphId)
                  .toDouble();
            }
            paragraphClusters.add(KhmerLayoutCluster.space(
              spaceGlyphId: shaper.spaceGlyphId,
              advanceFontUnits: advUnits,
              fontSize: fontSize,
              unitsPerEm: unitsPerEm,
              sourceStart: token.sourceStart,
              sourceEnd: token.sourceEnd,
            ));
            break;

          case KhmerLayoutTokenType.nbsp:
            double advUnits;
            if (latinFont != null) {
              final spaceMetrics = latinFont.stringMetrics(' ');
              final widthPts = spaceMetrics.advanceWidth * fontSize;
              advUnits = widthPts * unitsPerEm / fontSize;
            } else {
              final nbspGid = shaper.cmap.glyphIdForCodePoint(0x00A0);
              final effectiveGid =
                  (nbspGid != 0) ? nbspGid : shaper.spaceGlyphId;
              advUnits =
                  shaper.metrics.advanceWidthForGlyph(effectiveGid).toDouble();
            }
            paragraphClusters.add(KhmerLayoutCluster.nbsp(
              spaceGlyphId: shaper.spaceGlyphId,
              advanceFontUnits: advUnits,
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
          lastBreakOpportunityIndex =
              _findLastBreakOpportunity(currentLineClusters);
          continue;
        } else {
          lines.add(
              _createLine(currentLineClusters, lineHeight, baselineOffset));
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
