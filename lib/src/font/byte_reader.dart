import 'dart:convert';
import 'dart:typed_data';

/// Exception thrown when binary parsing fails due to truncated or malformed data.
class FontParseException implements Exception {
  final String message;
  final int? offset;

  FontParseException(this.message, [this.offset]);

  @override
  String toString() => offset != null
      ? 'FontParseException at byte offset $offset: $message'
      : 'FontParseException: $message';
}

/// A safe, bounds-checked big-endian binary buffer reader for OpenType/sfnt tables.
class ByteReader {
  final Uint8List _bytes;
  final ByteData _byteData;
  int _offset;

  ByteReader(Uint8List bytes, [this._offset = 0])
      : _bytes = bytes,
        _byteData = ByteData.sublistView(bytes);

  /// Current byte offset.
  int get offset => _offset;

  /// Total length in bytes.
  int get length => _bytes.length;

  /// Remaining unread bytes.
  int get remaining => _bytes.length - _offset;

  /// Sets the reading offset with bounds checking.
  void seek(int offset) {
    if (offset < 0 || offset > _bytes.length) {
      throw FontParseException(
        'Seek offset $offset out of bounds (0..${_bytes.length})',
        offset,
      );
    }
    _offset = offset;
  }

  /// Skips [count] bytes forward.
  void skip(int count) {
    seek(_offset + count);
  }

  void _checkBounds(int size) {
    if (_offset + size > _bytes.length) {
      throw FontParseException(
        'Unexpected end of buffer: requested $size bytes at offset $_offset, but total length is ${_bytes.length}',
        _offset,
      );
    }
  }

  /// Reads an unsigned 8-bit integer.
  int readUint8() {
    _checkBounds(1);
    final value = _bytes[_offset];
    _offset += 1;
    return value;
  }

  /// Reads a signed 8-bit integer.
  int readInt8() {
    _checkBounds(1);
    final value = _byteData.getInt8(_offset);
    _offset += 1;
    return value;
  }

  /// Reads an unsigned 16-bit big-endian integer.
  int readUint16() {
    _checkBounds(2);
    final value = _byteData.getUint16(_offset, Endian.big);
    _offset += 2;
    return value;
  }

  /// Reads a signed 16-bit big-endian integer.
  int readInt16() {
    _checkBounds(2);
    final value = _byteData.getInt16(_offset, Endian.big);
    _offset += 2;
    return value;
  }

  /// Reads an unsigned 32-bit big-endian integer.
  int readUint32() {
    _checkBounds(4);
    final value = _byteData.getUint32(_offset, Endian.big);
    _offset += 4;
    return value;
  }

  /// Reads a signed 32-bit big-endian integer.
  int readInt32() {
    _checkBounds(4);
    final value = _byteData.getInt32(_offset, Endian.big);
    _offset += 4;
    return value;
  }

  /// Reads a 4-byte ASCII OpenType tag (e.g. 'cmap', 'GSUB', 'khmr').
  String readTag() {
    _checkBounds(4);
    final tagBytes = _bytes.sublist(_offset, _offset + 4);
    _offset += 4;
    return ascii.decode(tagBytes);
  }

  /// Reads an unsigned 16-bit offset.
  int readOffset16() => readUint16();

  /// Reads an unsigned 32-bit offset.
  int readOffset32() => readUint32();

  /// Gets an unsigned 16-bit integer at absolute offset without advancing pointer.
  int getUint16(int offset) {
    if (offset < 0 || offset + 2 > _bytes.length) {
      throw FontParseException(
        'getUint16 offset $offset out of bounds (length ${_bytes.length})',
        offset,
      );
    }
    return _byteData.getUint16(offset, Endian.big);
  }

  /// Gets an unsigned 8-bit integer at absolute offset without advancing pointer.
  int getUint8(int offset) {
    if (offset < 0 || offset + 1 > _bytes.length) {
      throw FontParseException(
        'getUint8 offset $offset out of bounds (length ${_bytes.length})',
        offset,
      );
    }
    return _bytes[offset];
  }

  /// Gets an unsigned 32-bit integer at absolute offset without advancing pointer.
  int getUint32(int offset) {
    if (offset < 0 || offset + 4 > _bytes.length) {
      throw FontParseException(
        'getUint32 offset $offset out of bounds (length ${_bytes.length})',
        offset,
      );
    }
    return _byteData.getUint32(offset, Endian.big);
  }

  /// Creates a sub-slice [ByteReader] starting at [offset] with optional [length].
  ByteReader slice(int offset, [int? length]) {
    if (offset < 0 || offset > _bytes.length) {
      throw FontParseException(
        'Slice offset $offset out of bounds (0..${_bytes.length})',
        offset,
      );
    }
    final len = length ?? (_bytes.length - offset);
    if (len < 0 || offset + len > _bytes.length) {
      throw FontParseException(
        'Slice range ($offset..${offset + len}) out of bounds (length ${_bytes.length})',
        offset,
      );
    }
    return ByteReader(Uint8List.sublistView(_bytes, offset, offset + len));
  }

  /// Returns the underlying byte buffer.
  Uint8List get rawBytes => _bytes;
}
