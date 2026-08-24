import 'byte_reader.dart';

/// A segment in cmap Format 4.
class CmapFormat4Segment {
  final int startCode;
  final int endCode;
  final int idDelta;
  final int idRangeOffset;
  final int idRangeOffsetByteOffset;

  const CmapFormat4Segment({
    required this.startCode,
    required this.endCode,
    required this.idDelta,
    required this.idRangeOffset,
    required this.idRangeOffsetByteOffset,
  });
}

/// Parser and glyph ID resolver for OpenType `cmap` Format 4 tables.
class CmapTable {
  final List<CmapFormat4Segment> _segments;
  final ByteReader _subtableReader;

  CmapTable._(this._segments, this._subtableReader);

  /// Parses the cmap table and selects the Unicode Format 4 subtable deterministically.
  factory CmapTable.parse(ByteReader reader) {
    reader.seek(0);
    final version = reader.readUint16();
    if (version != 0) {
      throw FontParseException('Unsupported cmap table version: $version', 0);
    }
    final numTables = reader.readUint16();

    int? selectedOffset;
    // Prefer Platform 3, Encoding 1 (Windows Unicode BMP) or Platform 0, Encoding 3 (Unicode 2.0+)
    for (int i = 0; i < numTables; i++) {
      final platformId = reader.readUint16();
      final encodingId = reader.readUint16();
      final subtableOffset = reader.readOffset32();

      if ((platformId == 3 && encodingId == 1) ||
          (platformId == 0 && encodingId == 3)) {
        selectedOffset = subtableOffset;
        break;
      }
    }

    if (selectedOffset == null) {
      throw FontParseException('No suitable Unicode Format 4 cmap subtable found in font.');
    }

    final subtableReader = reader.slice(selectedOffset);
    final format = subtableReader.readUint16();
    if (format != 4) {
      throw FontParseException('Selected cmap subtable is not Format 4 (format: $format)', selectedOffset);
    }

    subtableReader.skip(4); // subtableLength (2), language (2)
    final segCountX2 = subtableReader.readUint16();
    final segCount = segCountX2 ~/ 2;
    subtableReader.skip(6); // searchRange, entrySelector, rangeShift

    final endCodes = List<int>.generate(segCount, (_) => subtableReader.readUint16());
    final reservedPad = subtableReader.readUint16();
    if (reservedPad != 0) {
      // Per spec reservedPad should be 0, but continue safely
    }
    final startCodes = List<int>.generate(segCount, (_) => subtableReader.readUint16());
    final idDeltas = List<int>.generate(segCount, (_) => subtableReader.readInt16());

    final idRangeOffsets = <int>[];
    final idRangeOffsetByteOffsets = <int>[];
    for (int i = 0; i < segCount; i++) {
      idRangeOffsetByteOffsets.add(subtableReader.offset);
      idRangeOffsets.add(subtableReader.readUint16());
    }

    final segments = <CmapFormat4Segment>[];
    for (int i = 0; i < segCount; i++) {
      segments.add(CmapFormat4Segment(
        startCode: startCodes[i],
        endCode: endCodes[i],
        idDelta: idDeltas[i],
        idRangeOffset: idRangeOffsets[i],
        idRangeOffsetByteOffset: idRangeOffsetByteOffsets[i],
      ));
    }

    return CmapTable._(segments, subtableReader);
  }

  /// Maps a Unicode [codePoint] to its initial glyph ID in the font.
  /// Returns 0 (`.notdef`) if the code point is unmapped.
  int glyphIdForCodePoint(int codePoint) {
    if (codePoint < 0 || codePoint > 0xFFFF) {
      return 0; // Format 4 only supports BMP (0x0000..0xFFFF)
    }

    // Binary search through segments
    int low = 0;
    int high = _segments.length - 1;
    int segIdx = -1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (_segments[mid].endCode >= codePoint) {
        segIdx = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    if (segIdx == -1) return 0;

    final seg = _segments[segIdx];
    if (codePoint < seg.startCode) return 0;

    if (seg.idRangeOffset == 0) {
      return (codePoint + seg.idDelta) & 0xFFFF;
    } else {
      // idRangeOffset arithmetic per OpenType spec
      final glyphOffset = seg.idRangeOffsetByteOffset +
          seg.idRangeOffset +
          2 * (codePoint - seg.startCode);

      if (glyphOffset + 2 > _subtableReader.length) {
        return 0;
      }

      final glyphId = _subtableReader.getUint16(glyphOffset);
      if (glyphId == 0) return 0;
      return (glyphId + seg.idDelta) & 0xFFFF;
    }
  }
}
