import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_cid_registry.dart';

void main() {
  group('KhmerCidRegistry Tests', () {
    late KhmerCidRegistry registry;

    setUp(() {
      registry = KhmerCidRegistry();
    });

    test('Reserves CID 0 for .notdef', () {
      expect(registry.maxCid, equals(0));
      expect(registry.count, equals(1));
      final notdef = registry.getByCid(0);
      expect(notdef, isNotNull);
      expect(notdef!.cid, equals(0));
      expect(notdef.subsetGlyphId, equals(0));
    });

    test('Allocates sequential CIDs deterministically', () {
      final code1 = registry.allocate(
        originalGlyphId: 53,
        subsetGlyphId: 1,
        unicodeText: 'ក',
      );
      final code2 = registry.allocate(
        originalGlyphId: 205,
        subsetGlyphId: 2,
        unicodeText: '្រ',
      );

      expect(code1.cid, equals(1));
      expect(code2.cid, equals(2));
      expect(registry.maxCid, equals(2));
      expect(registry.count, equals(3));
    });

    test('Reuses existing CID for identical (subsetGlyphId, unicodeText)', () {
      final code1 = registry.allocate(
        originalGlyphId: 53,
        subsetGlyphId: 1,
        unicodeText: 'ក',
      );
      final code2 = registry.allocate(
        originalGlyphId: 53,
        subsetGlyphId: 1,
        unicodeText: 'ក',
      );

      expect(code1.cid, equals(code2.cid));
      expect(registry.count, equals(2)); // CID 0 and CID 1
    });

    test(
        'Allocates distinct CIDs for same physical subsetGlyphId with different unicodeText',
        () {
      // Physical subscript Ka (subset GID 4) appearing in "ក្ក" and "ង្ក"
      final codeA = registry.allocate(
        originalGlyphId: 295,
        subsetGlyphId: 4,
        unicodeText: 'ក្ក',
      );
      final codeB = registry.allocate(
        originalGlyphId: 295,
        subsetGlyphId: 4,
        unicodeText: 'ង្ក',
      );

      expect(codeA.subsetGlyphId, equals(codeB.subsetGlyphId));
      expect(codeA.originalGlyphId, equals(codeB.originalGlyphId));
      expect(codeA.cid, isNot(equals(codeB.cid)));
      expect(codeA.unicodeText, equals('ក្ក'));
      expect(codeB.unicodeText, equals('ង្ក'));
    });
  });
}
