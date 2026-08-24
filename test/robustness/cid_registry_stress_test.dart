import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_cid_registry.dart';

void main() {
  group('Phase 7 — Item 11: CID Registry Stress Tests', () {
    test('Allocates 5,000 distinct semantic clusters deterministically', () {
      final registry = KhmerCidRegistry();

      expect(registry.count, equals(1)); // CID 0 (.notdef)

      for (int i = 1; i <= 5000; i++) {
        final code = registry.allocate(
          originalGlyphId: (i % 300) + 1,
          subsetGlyphId: 0,
          unicodeText: 'cluster_$i',
        );
        expect(code.cid, equals(i));
      }

      expect(registry.maxCid, equals(5000));
      expect(registry.count, equals(5001));

      // Re-allocating identical keys returns existing CIDs without inflating registry
      for (int i = 1; i <= 5000; i++) {
        final code = registry.allocate(
          originalGlyphId: (i % 300) + 1,
          subsetGlyphId: 0,
          unicodeText: 'cluster_$i',
        );
        expect(code.cid, equals(i));
      }

      expect(registry.maxCid, equals(5000));
      expect(registry.count, equals(5001));
    });

    test(
        'Same physical original GID correctly maps from multiple distinct CIDs',
        () {
      final registry = KhmerCidRegistry();

      const sharedGid = 53; // Base consonant 'ក'
      final code1 = registry.allocate(
        originalGlyphId: sharedGid,
        subsetGlyphId: 0,
        unicodeText: 'ក',
      );
      final code2 = registry.allocate(
        originalGlyphId: sharedGid,
        subsetGlyphId: 0,
        unicodeText: 'កា',
      );
      final code3 = registry.allocate(
        originalGlyphId: sharedGid,
        subsetGlyphId: 0,
        unicodeText: 'កុ',
      );

      expect(code1.cid, equals(1));
      expect(code2.cid, equals(2));
      expect(code3.cid, equals(3));

      expect(code1.originalGlyphId, equals(sharedGid));
      expect(code2.originalGlyphId, equals(sharedGid));
      expect(code3.originalGlyphId, equals(sharedGid));

      expect(code1.unicodeText, equals('ក'));
      expect(code2.unicodeText, equals('កា'));
      expect(code3.unicodeText, equals('កុ'));
    });
  });
}
