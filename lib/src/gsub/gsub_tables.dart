import 'dart:math' as math;
import '../font/byte_reader.dart';
import 'coverage_table.dart';

/// Mutable glyph representation during GSUB layout shaping.
class ShapingGlyph {
  int glyphId;
  int cluster;
  int sourceStart;
  int sourceEnd;
  int featureMask;
  bool isSynthetic;
  bool isDefaultIgnorable;

  ShapingGlyph({
    required this.glyphId,
    required this.cluster,
    required this.sourceStart,
    required this.sourceEnd,
    this.featureMask = 0,
    this.isSynthetic = false,
    this.isDefaultIgnorable = false,
  });

  ShapingGlyph clone() => ShapingGlyph(
        glyphId: glyphId,
        cluster: cluster,
        sourceStart: sourceStart,
        sourceEnd: sourceEnd,
        featureMask: featureMask,
        isSynthetic: isSynthetic,
        isDefaultIgnorable: isDefaultIgnorable,
      );

  @override
  String toString() =>
      'ShapingGlyph(gid: $glyphId, cluster: $cluster, src: $sourceStart..$sourceEnd, mask: $featureMask)';
}

/// Signature for applying a nested lookup at a specific buffer position.
typedef LookupApplier = bool Function(
    int lookupIndex, List<ShapingGlyph> buffer, int position);

/// Abstract base class for GSUB subtables.
abstract class GsubSubtable {
  bool apply(
      List<ShapingGlyph> buffer, int position, LookupApplier applyLookup);
}

/// GSUB Type 1: Single Substitution (Formats 1 & 2).
class SingleSubst implements GsubSubtable {
  final int format;
  final CoverageTable coverage;
  final int deltaGlyphId;
  final List<int>? substituteGlyphIds;

  SingleSubst.format1({
    required this.coverage,
    required this.deltaGlyphId,
  })  : format = 1,
        substituteGlyphIds = null;

  SingleSubst.format2({
    required this.coverage,
    required this.substituteGlyphIds,
  })  : format = 2,
        deltaGlyphId = 0;

  factory SingleSubst.parse(ByteReader subtableReader) {
    final subtableStart = subtableReader.offset;
    final format = subtableReader.readUint16();
    final coverageOffset = subtableReader.readOffset16();

    final coverageReader = subtableReader.slice(subtableStart + coverageOffset);
    final coverage = CoverageTable.parse(coverageReader);

    if (format == 1) {
      final deltaGlyphId = subtableReader.readInt16();
      return SingleSubst.format1(
        coverage: coverage,
        deltaGlyphId: deltaGlyphId,
      );
    } else if (format == 2) {
      final glyphCount = subtableReader.readUint16();
      final substituteGlyphIds = List<int>.generate(
        glyphCount,
        (_) => subtableReader.readUint16(),
      );
      return SingleSubst.format2(
        coverage: coverage,
        substituteGlyphIds: substituteGlyphIds,
      );
    } else {
      throw FontParseException('Unsupported SingleSubst format: $format');
    }
  }

  /// Resolves the replacement glyph ID for [glyphId], or `null` if not matched.
  int? substitute(int glyphId) {
    final covIdx = coverage.coverageIndex(glyphId);
    if (covIdx == null) return null;

    if (format == 1) {
      return (glyphId + deltaGlyphId) & 0xFFFF;
    } else {
      if (covIdx < substituteGlyphIds!.length) {
        return substituteGlyphIds![covIdx];
      }
      return null;
    }
  }

  @override
  bool apply(
      List<ShapingGlyph> buffer, int position, LookupApplier applyLookup) {
    if (position < 0 || position >= buffer.length) return false;
    final glyph = buffer[position];
    final newGid = substitute(glyph.glyphId);
    if (newGid != null) {
      glyph.glyphId = newGid;
      glyph.isDefaultIgnorable = false;
      return true;
    }
    return false;
  }
}

/// A single ligature representation in GSUB Type 4.
class Ligature {
  final int ligGlyphId;
  final List<int> componentGlyphIds;

  const Ligature({
    required this.ligGlyphId,
    required this.componentGlyphIds,
  });
}

/// GSUB Type 4: Ligature Substitution (Format 1).
class LigatureSubst implements GsubSubtable {
  final CoverageTable coverage;
  final List<List<Ligature>> ligatureSets;

  LigatureSubst({
    required this.coverage,
    required this.ligatureSets,
  });

  factory LigatureSubst.parse(ByteReader subtableReader) {
    final subtableStart = subtableReader.offset;
    final format = subtableReader.readUint16();
    if (format != 1) {
      throw FontParseException('Unsupported LigatureSubst format: $format');
    }

    final coverageOffset = subtableReader.readOffset16();
    final ligSetCount = subtableReader.readUint16();
    final ligSetOffsets = List<int>.generate(
      ligSetCount,
      (_) => subtableReader.readOffset16(),
    );

    final coverageReader = subtableReader.slice(subtableStart + coverageOffset);
    final coverage = CoverageTable.parse(coverageReader);

    final ligatureSets = <List<Ligature>>[];
    for (final ligSetOffset in ligSetOffsets) {
      final ligSetReader = subtableReader.slice(subtableStart + ligSetOffset);
      final ligCount = ligSetReader.readUint16();
      final ligOffsets = List<int>.generate(
        ligCount,
        (_) => ligSetReader.readOffset16(),
      );

      final ligatures = <Ligature>[];
      for (final ligOffset in ligOffsets) {
        final ligReader =
            subtableReader.slice(subtableStart + ligSetOffset + ligOffset);
        final ligGlyphId = ligReader.readUint16();
        final compCount = ligReader.readUint16();
        // compCount is total glyphs in ligature; componentGlyphIds contains 2nd..Nth glyphs
        final components = List<int>.generate(
          compCount - 1,
          (_) => ligReader.readUint16(),
        );
        ligatures.add(Ligature(
          ligGlyphId: ligGlyphId,
          componentGlyphIds: components,
        ));
      }
      ligatureSets.add(ligatures);
    }

    return LigatureSubst(
      coverage: coverage,
      ligatureSets: ligatureSets,
    );
  }

  @override
  bool apply(
      List<ShapingGlyph> buffer, int position, LookupApplier applyLookup) {
    if (position < 0 || position >= buffer.length) return false;
    final firstGid = buffer[position].glyphId;
    final covIdx = coverage.coverageIndex(firstGid);
    if (covIdx == null || covIdx >= ligatureSets.length) return false;

    final ligatures = ligatureSets[covIdx];
    for (final lig in ligatures) {
      final compCount = lig.componentGlyphIds.length;
      if (position + 1 + compCount > buffer.length) continue;

      bool matched = true;
      for (int i = 0; i < compCount; i++) {
        if (buffer[position + 1 + i].glyphId != lig.componentGlyphIds[i]) {
          matched = false;
          break;
        }
      }

      if (matched) {
        // Matched ligature!
        final matchedSlice = buffer.sublist(position, position + 1 + compCount);

        int minCluster = matchedSlice[0].cluster;
        int minStart = matchedSlice[0].sourceStart;
        int maxEnd = matchedSlice[0].sourceEnd;
        int combinedMask = 0;
        bool anySynthetic = false;

        for (final g in matchedSlice) {
          minCluster = math.min(minCluster, g.cluster);
          minStart = math.min(minStart, g.sourceStart);
          maxEnd = math.max(maxEnd, g.sourceEnd);
          combinedMask |= g.featureMask;
          if (g.isSynthetic) anySynthetic = true;
        }

        final replacementGlyph = ShapingGlyph(
          glyphId: lig.ligGlyphId,
          cluster: minCluster,
          sourceStart: minStart,
          sourceEnd: maxEnd,
          featureMask: combinedMask,
          isSynthetic: anySynthetic,
          isDefaultIgnorable: false,
        );

        buffer.replaceRange(
            position, position + 1 + compCount, [replacementGlyph]);
        return true;
      }
    }

    return false;
  }
}

/// Record mapping an input sequence position to a lookup list index in Type 6 substitutions.
class SubstLookupRecord {
  final int sequenceIndex;
  final int lookupListIndex;

  const SubstLookupRecord({
    required this.sequenceIndex,
    required this.lookupListIndex,
  });
}

/// GSUB Type 6: Chaining Contextual Substitution (Format 3).
class ChainContextSubstFormat3 implements GsubSubtable {
  final List<CoverageTable> backtrackCoverages;
  final List<CoverageTable> inputCoverages;
  final List<CoverageTable> lookaheadCoverages;
  final List<SubstLookupRecord> substLookupRecords;

  ChainContextSubstFormat3({
    required this.backtrackCoverages,
    required this.inputCoverages,
    required this.lookaheadCoverages,
    required this.substLookupRecords,
  });

  factory ChainContextSubstFormat3.parse(ByteReader subtableReader) {
    final subtableStart = subtableReader.offset;
    final format = subtableReader.readUint16();
    if (format != 3) {
      throw FontParseException('Unsupported ChainContextSubst format: $format');
    }

    // 1. Backtrack coverages
    final backtrackCount = subtableReader.readUint16();
    final backtrackOffsets = List<int>.generate(
      backtrackCount,
      (_) => subtableReader.readOffset16(),
    );

    // 2. Input coverages
    final inputCount = subtableReader.readUint16();
    final inputOffsets = List<int>.generate(
      inputCount,
      (_) => subtableReader.readOffset16(),
    );

    // 3. Lookahead coverages
    final lookaheadCount = subtableReader.readUint16();
    final lookaheadOffsets = List<int>.generate(
      lookaheadCount,
      (_) => subtableReader.readOffset16(),
    );

    // 4. SubstLookupRecords
    final seqLookupCount = subtableReader.readUint16();
    final records = <SubstLookupRecord>[];
    for (int i = 0; i < seqLookupCount; i++) {
      final sequenceIndex = subtableReader.readUint16();
      final lookupListIndex = subtableReader.readUint16();
      records.add(SubstLookupRecord(
        sequenceIndex: sequenceIndex,
        lookupListIndex: lookupListIndex,
      ));
    }

    // Parse all coverage tables
    final backtrackCoverages = backtrackOffsets.map((off) {
      final r = subtableReader.slice(subtableStart + off);
      return CoverageTable.parse(r);
    }).toList();

    final inputCoverages = inputOffsets.map((off) {
      final r = subtableReader.slice(subtableStart + off);
      return CoverageTable.parse(r);
    }).toList();

    final lookaheadCoverages = lookaheadOffsets.map((off) {
      final r = subtableReader.slice(subtableStart + off);
      return CoverageTable.parse(r);
    }).toList();

    return ChainContextSubstFormat3(
      backtrackCoverages: backtrackCoverages,
      inputCoverages: inputCoverages,
      lookaheadCoverages: lookaheadCoverages,
      substLookupRecords: records,
    );
  }

  /// Checks if the rule matches at [position].
  bool matches(List<ShapingGlyph> buffer, int position) {
    // 1. Check backtrack
    final backLen = backtrackCoverages.length;
    if (position < backLen) return false;
    for (int i = 0; i < backLen; i++) {
      // BacktrackCoverage[0] matches buffer[pos - 1], [1] matches buffer[pos - 2], etc.
      if (!backtrackCoverages[i].covers(buffer[position - 1 - i].glyphId)) {
        return false;
      }
    }

    // 2. Check input
    final inpLen = inputCoverages.length;
    if (position + inpLen > buffer.length) return false;
    for (int i = 0; i < inpLen; i++) {
      if (!inputCoverages[i].covers(buffer[position + i].glyphId)) {
        return false;
      }
    }

    // 3. Check lookahead
    final lookLen = lookaheadCoverages.length;
    if (position + inpLen + lookLen > buffer.length) return false;
    for (int i = 0; i < lookLen; i++) {
      if (!lookaheadCoverages[i]
          .covers(buffer[position + inpLen + i].glyphId)) {
        return false;
      }
    }

    return true;
  }

  @override
  bool apply(
      List<ShapingGlyph> buffer, int position, LookupApplier applyLookup) {
    if (!matches(buffer, position)) return false;

    // Apply SubstLookupRecords in order to the matched input sequence
    for (final record in substLookupRecords) {
      final targetPos = position + record.sequenceIndex;
      applyLookup(record.lookupListIndex, buffer, targetPos);
    }

    return true;
  }
}
