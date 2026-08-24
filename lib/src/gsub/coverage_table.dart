import '../font/byte_reader.dart';

/// Range record in Coverage Format 2.
class CoverageRangeRecord {
  final int startGlyphId;
  final int endGlyphId;
  final int startCoverageIndex;

  const CoverageRangeRecord({
    required this.startGlyphId,
    required this.endGlyphId,
    required this.startCoverageIndex,
  });
}

/// Abstract base class for OpenType GSUB/GPOS Coverage tables.
abstract class CoverageTable {
  /// Returns the 0-based coverage index of [glyphId], or `null` if not covered.
  int? coverageIndex(int glyphId);

  /// Whether [glyphId] is covered.
  bool covers(int glyphId) => coverageIndex(glyphId) != null;

  /// Parses a coverage table from [reader] starting at the current offset.
  factory CoverageTable.parse(ByteReader reader) {
    final format = reader.readUint16();
    if (format == 1) {
      final glyphCount = reader.readUint16();
      final glyphArray = List<int>.generate(glyphCount, (_) => reader.readUint16());
      return CoverageFormat1(glyphArray);
    } else if (format == 2) {
      final rangeCount = reader.readUint16();
      final ranges = <CoverageRangeRecord>[];
      for (int i = 0; i < rangeCount; i++) {
        final startGlyphId = reader.readUint16();
        final endGlyphId = reader.readUint16();
        final startCoverageIndex = reader.readUint16();
        ranges.add(CoverageRangeRecord(
          startGlyphId: startGlyphId,
          endGlyphId: endGlyphId,
          startCoverageIndex: startCoverageIndex,
        ));
      }
      return CoverageFormat2(ranges);
    } else {
      throw FontParseException('Unsupported Coverage table format: $format');
    }
  }
}

/// Coverage Format 1: Individual glyph IDs.
class CoverageFormat1 implements CoverageTable {
  final List<int> glyphArray;

  CoverageFormat1(this.glyphArray);

  @override
  bool covers(int glyphId) => coverageIndex(glyphId) != null;

  @override
  int? coverageIndex(int glyphId) {
    int low = 0;
    int high = glyphArray.length - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final val = glyphArray[mid];
      if (val == glyphId) {
        return mid;
      } else if (val < glyphId) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return null;
  }
}

/// Coverage Format 2: Range records.
class CoverageFormat2 implements CoverageTable {
  final List<CoverageRangeRecord> rangeRecords;

  CoverageFormat2(this.rangeRecords);

  @override
  bool covers(int glyphId) => coverageIndex(glyphId) != null;

  @override
  int? coverageIndex(int glyphId) {
    int low = 0;
    int high = rangeRecords.length - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final range = rangeRecords[mid];
      if (glyphId >= range.startGlyphId && glyphId <= range.endGlyphId) {
        return range.startCoverageIndex + (glyphId - range.startGlyphId);
      } else if (glyphId < range.startGlyphId) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    return null;
  }
}
