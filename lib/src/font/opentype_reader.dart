import 'dart:typed_data';
import 'byte_reader.dart';

/// Metadata record for a single table in the sfnt table directory.
class TableRecord {
  final String tag;
  final int checksum;
  final int offset;
  final int length;

  const TableRecord({
    required this.tag,
    required this.checksum,
    required this.offset,
    required this.length,
  });

  @override
  String toString() => 'TableRecord($tag, offset: $offset, len: $length)';
}

/// Minimal sfnt / OpenType font table directory reader.
class OpenTypeFont {
  final Uint8List fontBytes;
  final int sfntVersion;
  final Map<String, TableRecord> tables;

  OpenTypeFont._({
    required this.fontBytes,
    required this.sfntVersion,
    required this.tables,
  });

  /// Parses the sfnt table directory from [fontBytes].
  factory OpenTypeFont.parse(Uint8List fontBytes) {
    if (fontBytes.length < 12) {
      throw FontParseException(
        'Font file is too short to contain an sfnt table directory (${fontBytes.length} bytes)',
      );
    }

    final reader = ByteReader(fontBytes);
    final sfntVersion = reader.readUint32();
    final numTables = reader.readUint16();
    reader.skip(6); // searchRange (2), entrySelector (2), rangeShift (2)

    final expectedMinLength = 12 + numTables * 16;
    if (fontBytes.length < expectedMinLength) {
      throw FontParseException(
        'Font file truncated: required at least $expectedMinLength bytes for $numTables table records, but found ${fontBytes.length} bytes',
      );
    }

    final tables = <String, TableRecord>{};
    for (int i = 0; i < numTables; i++) {
      final tag = reader.readTag();
      final checksum = reader.readUint32();
      final offset = reader.readUint32();
      final length = reader.readUint32();

      if (offset < 0 || offset + length > fontBytes.length) {
        throw FontParseException(
          'Table $tag has invalid byte range ($offset..${offset + length}) exceeding font buffer (${fontBytes.length} bytes)',
          offset,
        );
      }

      tables[tag] = TableRecord(
        tag: tag,
        checksum: checksum,
        offset: offset,
        length: length,
      );
    }

    return OpenTypeFont._(
      fontBytes: fontBytes,
      sfntVersion: sfntVersion,
      tables: Map.unmodifiable(tables),
    );
  }

  /// Checks if table with [tag] exists.
  bool hasTable(String tag) => tables.containsKey(tag);

  /// Returns [ByteReader] for the table slice corresponding to [tag].
  /// Throws [FontParseException] if the table does not exist.
  ByteReader getTableReader(String tag) {
    final record = tables[tag];
    if (record == null) {
      throw FontParseException(
          'Required OpenType table "$tag" not found in font.');
    }
    return ByteReader(
      Uint8List.sublistView(
        fontBytes,
        record.offset,
        record.offset + record.length,
      ),
    );
  }

  /// Returns byte sublist for table [tag].
  Uint8List getTableBytes(String tag) {
    final record = tables[tag];
    if (record == null) {
      throw FontParseException(
          'Required OpenType table "$tag" not found in font.');
    }
    return Uint8List.sublistView(
      fontBytes,
      record.offset,
      record.offset + record.length,
    );
  }
}
