import 'byte_reader.dart';

/// Single glyph horizontal metric record.
class GlyphMetric {
  final int advanceWidth;
  final int leftSideBearing;

  const GlyphMetric({
    required this.advanceWidth,
    required this.leftSideBearing,
  });
}

/// Horizontal metrics table parser and advance width resolver.
class MetricsTable {
  final int unitsPerEm;
  final int numGlyphs;
  final int numberOfHMetrics;
  final List<int> _advanceWidths;
  final List<int> _leftSideBearings;

  MetricsTable._({
    required this.unitsPerEm,
    required this.numGlyphs,
    required this.numberOfHMetrics,
    required List<int> advanceWidths,
    required List<int> leftSideBearings,
  })  : _advanceWidths = advanceWidths,
        _leftSideBearings = leftSideBearings;

  /// Parses `head`, `hhea`, `maxp`, and `hmtx` tables from their respective readers.
  factory MetricsTable.parse({
    required ByteReader headReader,
    required ByteReader hheaReader,
    required ByteReader maxpReader,
    required ByteReader hmtxReader,
  }) {
    // 1. Parse head table
    headReader.seek(0);
    headReader.skip(4); // headMajor (2), headMinor (2)
    headReader.skip(
        14); // fontRevision (4), checkSumAdjustment (4), magicNumber (4), flags (2)
    final unitsPerEm = headReader.readUint16();

    // 2. Parse maxp table
    maxpReader.seek(0);
    maxpReader.skip(4); // maxpVersion (4)
    final numGlyphs = maxpReader.readUint16();

    // 3. Parse hhea table
    hheaReader.seek(0);
    hheaReader.skip(4); // hheaMajor (2), hheaMinor (2)
    hheaReader.skip(30); // ascender, descender, lineGap, etc.
    final numberOfHMetrics = hheaReader.readUint16();

    if (numberOfHMetrics == 0) {
      throw FontParseException('hhea.numberOfHMetrics cannot be zero');
    }

    // 4. Parse hmtx table
    hmtxReader.seek(0);
    final advanceWidths = <int>[];
    final leftSideBearings = <int>[];

    for (int i = 0; i < numberOfHMetrics; i++) {
      advanceWidths.add(hmtxReader.readUint16());
      leftSideBearings.add(hmtxReader.readInt16());
    }

    final remainingGlyphs = numGlyphs - numberOfHMetrics;
    for (int i = 0; i < remainingGlyphs; i++) {
      leftSideBearings.add(hmtxReader.readInt16());
    }

    return MetricsTable._(
      unitsPerEm: unitsPerEm,
      numGlyphs: numGlyphs,
      numberOfHMetrics: numberOfHMetrics,
      advanceWidths: advanceWidths,
      leftSideBearings: leftSideBearings,
    );
  }

  /// Returns horizontal advance width for [glyphId] in font design units.
  /// Beyond [numberOfHMetrics], glyphs reuse the advance width of the last hmetric record.
  int advanceWidthForGlyph(int glyphId) {
    if (glyphId < 0 || glyphId >= numGlyphs) {
      return 0;
    }
    if (glyphId < numberOfHMetrics) {
      return _advanceWidths[glyphId];
    }
    return _advanceWidths[numberOfHMetrics - 1];
  }

  /// Returns left-side bearing for [glyphId] in font design units.
  int leftSideBearingForGlyph(int glyphId) {
    if (glyphId < 0 || glyphId >= numGlyphs) {
      return 0;
    }
    return _leftSideBearings[glyphId];
  }
}
