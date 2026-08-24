/// Record representing an allocated PDF Character Identifier (CID).
class PdfGlyphCode {
  /// The 16-bit PDF Character Identifier.
  final int cid;

  /// The physical glyph ID in the subset TrueType font (resolved at prepare time).
  final int subsetGlyphId;

  /// The original font glyph ID.
  final int originalGlyphId;

  /// The Unicode text slice mapped to this CID for copy/paste/search extraction.
  final String unicodeText;

  const PdfGlyphCode({
    required this.cid,
    required this.subsetGlyphId,
    required this.originalGlyphId,
    required this.unicodeText,
  });

  @override
  String toString() =>
      'PdfGlyphCode(cid: $cid, origGid: $originalGlyphId, u: "$unicodeText")';
}

/// Registry that manages deterministic CID allocation for shaped runs,
/// decoupling physical font glyph IDs from semantic Unicode cluster mappings.
class KhmerCidRegistry {
  /// CID 0 is reserved for .notdef / undefined glyphs per PDF specification.
  static const int notdefCid = 0;

  final Map<int, PdfGlyphCode> _cidEntries = {
    notdefCid: const PdfGlyphCode(
      cid: notdefCid,
      subsetGlyphId: 0,
      originalGlyphId: 0,
      unicodeText: '',
    ),
  };

  /// Cache for deduping identical (originalGlyphId, unicodeText) combinations.
  final Map<String, int> _keyToCid = {
    '0:': notdefCid,
  };

  int _nextCid = 1;

  /// Maximum allocated CID.
  int get maxCid => _nextCid - 1;

  /// Number of allocated CIDs including CID 0.
  int get count => _cidEntries.length;

  /// All allocated glyph codes indexed by CID.
  Map<int, PdfGlyphCode> get entries => Map.unmodifiable(_cidEntries);

  /// Allocates or retrieves an existing CID for the given [originalGlyphId] and [unicodeText].
  ///
  /// Different semantic occurrences with differing [unicodeText] will receive
  /// distinct CIDs while referencing the exact same physical [originalGlyphId].
  PdfGlyphCode allocate({
    required int originalGlyphId,
    required int subsetGlyphId,
    required String unicodeText,
  }) {
    final key = '$originalGlyphId:$unicodeText';
    final existingCid = _keyToCid[key];
    if (existingCid != null) {
      return _cidEntries[existingCid]!;
    }

    final cid = _nextCid++;
    final code = PdfGlyphCode(
      cid: cid,
      subsetGlyphId: subsetGlyphId,
      originalGlyphId: originalGlyphId,
      unicodeText: unicodeText,
    );

    _keyToCid[key] = cid;
    _cidEntries[cid] = code;
    return code;
  }

  /// Looks up an entry by [cid].
  PdfGlyphCode? getByCid(int cid) => _cidEntries[cid];
}
