import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:tamil_pdf_shaper/src/pdf/khmer_cid_to_gid_stream.dart';

void main() {
  group('KhmerCidToGidStream Tests', () {
    test('Encodes 2-byte big-endian integers for each CID', () {
      final doc = PdfDocument();
      final mapping = <int, int>{
        0: 0,
        1: 5,   // CID 1 -> subset GID 5
        2: 12,  // CID 2 -> subset GID 12
        3: 5,   // CID 3 -> subset GID 5 (repeated physical GID)
      };

      final stream = KhmerCidToGidStream(
        doc,
        cidToSubsetGid: mapping,
        maxCid: 3,
      );

      stream.prepare();

      final bytes = Uint8List.fromList(stream.buf.output());
      expect(bytes.length, equals(8)); // (3 + 1) * 2 = 8 bytes

      final byteData = bytes.buffer.asByteData();
      expect(byteData.getUint16(0), equals(0));   // CID 0 -> GID 0
      expect(byteData.getUint16(2), equals(5));   // CID 1 -> GID 5
      expect(byteData.getUint16(4), equals(12));  // CID 2 -> GID 12
      expect(byteData.getUint16(6), equals(5));   // CID 3 -> GID 5
    });

    test('Defaults unmapped CIDs up to maxCid to GID 0', () {
      final doc = PdfDocument();
      final mapping = <int, int>{
        0: 0,
        4: 25,
      };

      final stream = KhmerCidToGidStream(
        doc,
        cidToSubsetGid: mapping,
        maxCid: 4,
      );

      stream.prepare();

      final bytes = Uint8List.fromList(stream.buf.output());
      expect(bytes.length, equals(10)); // (4 + 1) * 2 = 10 bytes

      final byteData = bytes.buffer.asByteData();
      expect(byteData.getUint16(0), equals(0));
      expect(byteData.getUint16(2), equals(0)); // CID 1 unmapped -> 0
      expect(byteData.getUint16(4), equals(0)); // CID 2 unmapped -> 0
      expect(byteData.getUint16(6), equals(0)); // CID 3 unmapped -> 0
      expect(byteData.getUint16(8), equals(25)); // CID 4 -> 25
    });
  });
}
