import '../font/byte_reader.dart';
import '../khmer/khmer_features.dart';
import 'gsub_tables.dart';

/// Representation of an OpenType GSUB Lookup.
class GsubLookup {
  final int lookupType;
  final int lookupFlag;
  final List<GsubSubtable> subtables;

  GsubLookup({
    required this.lookupType,
    required this.lookupFlag,
    required this.subtables,
  });

  factory GsubLookup.parse(ByteReader lookupReader) {
    final lookupStart = lookupReader.offset;
    final lookupType = lookupReader.readUint16();
    final lookupFlag = lookupReader.readUint16();
    final subTableCount = lookupReader.readUint16();
    final subtableOffsets = List<int>.generate(
      subTableCount,
      (_) => lookupReader.readOffset16(),
    );

    final subtables = <GsubSubtable>[];
    for (final subOff in subtableOffsets) {
      final subReader = lookupReader.slice(lookupStart + subOff);
      if (lookupType == 1) {
        subtables.add(SingleSubst.parse(subReader));
      } else if (lookupType == 4) {
        subtables.add(LigatureSubst.parse(subReader));
      } else if (lookupType == 6) {
        subtables.add(ChainContextSubstFormat3.parse(subReader));
      } else {
        throw FontParseException('Unsupported GSUB LookupType: $lookupType');
      }
    }

    return GsubLookup(
      lookupType: lookupType,
      lookupFlag: lookupFlag,
      subtables: subtables,
    );
  }

  /// Attempts to apply any subtable at [position] in [buffer].
  bool apply(
      List<ShapingGlyph> buffer, int position, LookupApplier applyLookup) {
    for (final subtable in subtables) {
      if (subtable.apply(buffer, position, applyLookup)) {
        return true;
      }
    }
    return false;
  }
}

/// Feature metadata parsed from the GSUB FeatureList.
class GsubFeature {
  final String tag;
  final List<int> lookupIndices;

  const GsubFeature({
    required this.tag,
    required this.lookupIndices,
  });
}

/// Tracer callback for stage-by-stage debugging.
abstract class GsubTraceLogger {
  void logStage(String stageName, List<ShapingGlyph> buffer);
  void logLookup(int lookupIndex, String featureTag, int position,
      List<ShapingGlyph> bufferBefore, List<ShapingGlyph> bufferAfter);
}

/// Main GSUB table parser and layout evaluator for Khmer shaping.
class GsubTable {
  final List<GsubLookup> lookups;
  final Map<String, GsubFeature> features;
  final List<String> activeFeatureOrder;

  GsubTable._({
    required this.lookups,
    required this.features,
    required this.activeFeatureOrder,
  });

  factory GsubTable.parse(ByteReader reader) {
    reader.seek(0);
    reader.skip(4); // majorVersion (2), minorVersion (2)
    final scriptListOffset = reader.readOffset16();
    final featureListOffset = reader.readOffset16();
    final lookupListOffset = reader.readOffset16();

    // 1. Parse ScriptList -> locate 'khmr'
    final scriptListReader = reader.slice(scriptListOffset);
    final scriptCount = scriptListReader.readUint16();
    int? khmrDefaultLangSysOffset;
    int? khmrScriptOffset;

    for (int i = 0; i < scriptCount; i++) {
      final scriptTag = scriptListReader.readTag();
      final scriptOffset = scriptListReader.readOffset16();
      if (scriptTag == 'khmr') {
        khmrScriptOffset = scriptOffset;
        final scriptReader = scriptListReader.slice(scriptOffset);
        final defaultLangSysOffset = scriptReader.readOffset16();
        if (defaultLangSysOffset != 0) {
          khmrDefaultLangSysOffset = scriptOffset + defaultLangSysOffset;
        }
        break;
      }
    }

    if (khmrScriptOffset == null || khmrDefaultLangSysOffset == null) {
      throw FontParseException(
          'Script "khmr" with DefaultLangSys not found in GSUB table.');
    }

    final langSysReader = scriptListReader.slice(khmrDefaultLangSysOffset);
    langSysReader.skip(4); // lookupOrder (2), reqFeatureIndex (2)
    final featureIndexCount = langSysReader.readUint16();
    final khmrFeatureIndices = List<int>.generate(
      featureIndexCount,
      (_) => langSysReader.readUint16(),
    );

    // 2. Parse FeatureList
    final featureListReader = reader.slice(featureListOffset);
    final featureCount = featureListReader.readUint16();
    final allFeatures = <GsubFeature>[];

    for (int i = 0; i < featureCount; i++) {
      final tag = featureListReader.readTag();
      final featOffset = featureListReader.readOffset16();
      final featReader = featureListReader.slice(featOffset);
      featReader.skip(2); // featParamsOffset (2)
      final lookupCount = featReader.readUint16();
      final lookupIndices = List<int>.generate(
        lookupCount,
        (_) => featReader.readUint16(),
      );
      allFeatures.add(GsubFeature(tag: tag, lookupIndices: lookupIndices));
    }

    final activeFeatures = <String, GsubFeature>{};
    for (final featIdx in khmrFeatureIndices) {
      if (featIdx < allFeatures.length) {
        final feat = allFeatures[featIdx];
        activeFeatures[feat.tag] = feat;
      }
    }

    // 3. Parse LookupList
    final lookupListReader = reader.slice(lookupListOffset);
    final lookupCount = lookupListReader.readUint16();
    final lookupOffsets = List<int>.generate(
      lookupCount,
      (_) => lookupListReader.readOffset16(),
    );

    final lookups = <GsubLookup>[];
    for (final lOff in lookupOffsets) {
      final lReader = lookupListReader.slice(lOff);
      lookups.add(GsubLookup.parse(lReader));
    }

    return GsubTable._(
      lookups: lookups,
      features: activeFeatures,
      activeFeatureOrder: ['blwf', 'pref', 'pstf', 'abvs', 'clig'],
    );
  }

  /// Central lookup execution method with recursion depth guarding.
  bool applyLookup(
    int lookupIndex,
    List<ShapingGlyph> buffer,
    int position, [
    int depth = 0,
  ]) {
    if (depth > 8) {
      throw FontParseException(
          'Recursive GSUB lookup limit exceeded at lookup $lookupIndex');
    }
    if (lookupIndex < 0 || lookupIndex >= lookups.length) {
      throw FontParseException(
          'Invalid GSUB lookup index: $lookupIndex (total ${lookups.length})');
    }

    final lookup = lookups[lookupIndex];
    return lookup.apply(
      buffer,
      position,
      (nestedIdx, buf, pos) => applyLookup(nestedIdx, buf, pos, depth + 1),
    );
  }

  /// Evaluates GSUB features across [buffer] according to HarfBuzz Khmer order.
  void evaluate(
    List<ShapingGlyph> buffer, {
    GsubTraceLogger? tracer,
  }) {
    tracer?.logStage('CMAP', buffer);

    // 1. blwf (Below-base substitutions) [Masked]
    _applyFeature('blwf', buffer, mask: KhmerFeature.blwf, tracer: tracer);
    tracer?.logStage('FEATURE blwf', buffer);

    // 2. pref (Pre-base substitutions) [Masked]
    _applyFeature('pref', buffer, mask: KhmerFeature.pref, tracer: tracer);
    tracer?.logStage('FEATURE pref', buffer);

    // 3. pstf (Post-base substitutions) [Masked]
    _applyFeature('pstf', buffer, mask: KhmerFeature.pstf, tracer: tracer);
    tracer?.logStage('FEATURE pstf', buffer);

    // 4. abvs (Above-base substitutions) [Global in Battambang]
    _applyFeature('abvs', buffer, mask: null, tracer: tracer);
    tracer?.logStage('FEATURE abvs', buffer);

    // 5. clig (Contextual ligatures) [Global]
    _applyFeature('clig', buffer, mask: null, tracer: tracer);
    tracer?.logStage('FEATURE clig', buffer);

    tracer?.logStage('FINAL', buffer);
  }

  void _applyFeature(
    String featureTag,
    List<ShapingGlyph> buffer, {
    KhmerFeature? mask,
    GsubTraceLogger? tracer,
  }) {
    final feature = features[featureTag];
    if (feature == null) return;

    for (final lookupIndex in feature.lookupIndices) {
      int pos = 0;
      while (pos < buffer.length) {
        // Enforce Phase 2 feature mask if specified
        if (mask != null && (buffer[pos].featureMask & mask.mask) == 0) {
          pos++;
          continue;
        }

        final beforeState =
            tracer != null ? buffer.map((g) => g.clone()).toList() : null;
        final applied = applyLookup(lookupIndex, buffer, pos);

        if (applied && tracer != null && beforeState != null) {
          tracer.logLookup(
            lookupIndex,
            featureTag,
            pos,
            beforeState,
            buffer.map((g) => g.clone()).toList(),
          );
        }

        pos++;
      }
    }
  }
}
