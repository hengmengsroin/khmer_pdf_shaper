import 'khmer_category.dart';
import 'khmer_features.dart';

/// Represents a Unicode character (or synthetic piece) with script metadata,
/// exact UTF-16 source provenance, shaping cluster identifier, and feature masks.
class KhmerChar {
  /// Unicode code point (e.g. 0x1780 for 'ក').
  final int codePoint;

  /// UTF-16 code unit start offset in the original source string.
  final int sourceStart;

  /// UTF-16 code unit end offset (exclusive) in the original source string.
  final int sourceEnd;

  /// Shaping cluster identifier (monotone non-decreasing).
  /// In HarfBuzz, characters in a syllable share the cluster of the syllable's base.
  int cluster;

  /// Character category in HarfBuzz Indic/Khmer shaping model.
  final KhmerCategory category;

  /// OpenType feature mask bits.
  int featureMask;

  /// Whether this item was synthesized (e.g. Dotted Circle U+25CC or split-matra piece).
  final bool isSynthetic;

  /// Provenance tracking: original code points that generated this normalized item.
  final List<int> originalCodePoints;

  KhmerChar({
    required this.codePoint,
    required this.sourceStart,
    required this.sourceEnd,
    required this.cluster,
    required this.category,
    this.featureMask = 0,
    this.isSynthetic = false,
    List<int>? originalCodePoints,
  }) : originalCodePoints = originalCodePoints ?? [codePoint];

  /// Returns active feature set.
  KhmerFeatureSet get features => KhmerFeatureSet(featureMask);

  /// Semantic feature check.
  bool hasFeature(KhmerFeature feature) => features.has(feature);

  KhmerChar copyWith({
    int? codePoint,
    int? sourceStart,
    int? sourceEnd,
    int? cluster,
    KhmerCategory? category,
    int? featureMask,
    bool? isSynthetic,
    List<int>? originalCodePoints,
  }) {
    return KhmerChar(
      codePoint: codePoint ?? this.codePoint,
      sourceStart: sourceStart ?? this.sourceStart,
      sourceEnd: sourceEnd ?? this.sourceEnd,
      cluster: cluster ?? this.cluster,
      category: category ?? this.category,
      featureMask: featureMask ?? this.featureMask,
      isSynthetic: isSynthetic ?? this.isSynthetic,
      originalCodePoints: originalCodePoints ?? this.originalCodePoints,
    );
  }

  @override
  String toString() {
    final hexCp =
        'U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}';
    final featStr = features.toString();
    return 'KhmerChar($hexCp, src: $sourceStart..$sourceEnd, cluster: $cluster, cat: ${category.shortName}, feats: $featStr${isSynthetic ? ", synth" : ""})';
  }
}

/// Helper to decode Dart Strings into a stream of [KhmerChar]s with exact UTF-16 offsets.
class KhmerCharStream {
  KhmerCharStream._();

  /// Parses a UTF-16 Dart string into a list of [KhmerChar] objects.
  /// Correctly handles surrogate pairs without using naive `text[i]`.
  static List<KhmerChar> fromText(String text) {
    final List<KhmerChar> result = [];
    int i = 0;
    while (i < text.length) {
      final int start = i;
      final int cu1 = text.codeUnitAt(i);
      int codePoint = cu1;
      int end = i + 1;

      // Handle UTF-16 surrogate pairs
      if (cu1 >= 0xD800 && cu1 <= 0xDBFF && (i + 1) < text.length) {
        final int cu2 = text.codeUnitAt(i + 1);
        if (cu2 >= 0xDC00 && cu2 <= 0xDFFF) {
          codePoint = 0x10000 + ((cu1 - 0xD800) << 10) + (cu2 - 0xDC00);
          end = i + 2;
        }
      }

      final category = getKhmerCategory(codePoint);

      result.add(KhmerChar(
        codePoint: codePoint,
        sourceStart: start,
        sourceEnd: end,
        cluster: start,
        category: category,
        isSynthetic: false,
        originalCodePoints: [codePoint],
      ));

      i = end;
    }
    return result;
  }
}
