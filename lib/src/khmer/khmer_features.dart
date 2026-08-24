/// OpenType layout feature masks applied during Khmer script preprocessing.
enum KhmerFeature {
  pref(1 << 0, 'pref', 'Pre-base Substitutions / Pre-base glyph'),
  blwf(1 << 1, 'blwf', 'Below-base Forms / Subscripts'),
  abvf(1 << 2, 'abvf', 'Above-base Forms / Marks'),
  pstf(1 << 3, 'pstf', 'Post-base Forms'),
  cfar(1 << 4, 'cfar', 'Conjunct Form After Ro');

  final int mask;
  final String tag;
  final String description;

  const KhmerFeature(this.mask, this.tag, this.description);
}

/// A set of active OpenType layout features for a character or glyph.
class KhmerFeatureSet {
  final int mask;

  const KhmerFeatureSet([this.mask = 0]);

  bool has(KhmerFeature feature) => (mask & feature.mask) != 0;

  bool get hasPref => has(KhmerFeature.pref);
  bool get hasBlwf => has(KhmerFeature.blwf);
  bool get hasAbvf => has(KhmerFeature.abvf);
  bool get hasPstf => has(KhmerFeature.pstf);
  bool get hasCfar => has(KhmerFeature.cfar);

  List<String> get activeTags {
    final list = <String>[];
    for (final f in KhmerFeature.values) {
      if (has(f)) list.add(f.tag);
    }
    return list;
  }

  @override
  String toString() => activeTags.isEmpty ? '[]' : '[${activeTags.join(', ')}]';
}
