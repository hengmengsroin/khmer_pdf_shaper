import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_pdf_shaper/src/font/byte_reader.dart';
import 'package:tamil_pdf_shaper/src/font/opentype_reader.dart';

void main() {
  group('Part 2: OpenType Table Directory Reader Tests', () {
    late Uint8List fontBytes;

    setUpAll(() {
      fontBytes = File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
    });

    test('Parses sfnt directory and locates all required tables', () {
      final font = OpenTypeFont.parse(fontBytes);
      expect(font.hasTable('head'), isTrue);
      expect(font.hasTable('maxp'), isTrue);
      expect(font.hasTable('cmap'), isTrue);
      expect(font.hasTable('hhea'), isTrue);
      expect(font.hasTable('hmtx'), isTrue);
      expect(font.hasTable('GSUB'), isTrue);
    });

    test('Table readers return correct non-empty slices with bounds checks', () {
      final font = OpenTypeFont.parse(fontBytes);
      final headReader = font.getTableReader('head');
      expect(headReader.length, 54);

      final maxpReader = font.getTableReader('maxp');
      expect(maxpReader.length, 32);

      final cmapReader = font.getTableReader('cmap');
      expect(cmapReader.length, greaterThan(100));

      final gsubReader = font.getTableReader('GSUB');
      expect(gsubReader.length, 2750);
    });

    test('Rejects short buffer (< 12 bytes)', () {
      expect(
        () => OpenTypeFont.parse(Uint8List(8)),
        throwsA(isA<FontParseException>()),
      );
    });

    test('Rejects table request for missing table tag', () {
      final font = OpenTypeFont.parse(fontBytes);
      expect(
        () => font.getTableReader('FOOO'),
        throwsA(isA<FontParseException>()),
      );
    });

    test('ByteReader bounds checking prevents out-of-bounds reads', () {
      final reader = ByteReader(Uint8List.fromList([1, 2, 3]));
      expect(reader.readUint8(), 1);
      expect(reader.readUint16(), (2 << 8) | 3);
      expect(() => reader.readUint8(), throwsA(isA<FontParseException>()));
    });
  });
}
