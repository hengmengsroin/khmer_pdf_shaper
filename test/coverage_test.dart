import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/gsub/coverage_table.dart';

void main() {
  group('Part 11: Coverage Table Tests', () {
    test('Coverage Format 1 binary search and boundary resolution', () {
      final cov = CoverageFormat1([10, 20, 30, 40, 50]);

      expect(cov.coverageIndex(10), 0);
      expect(cov.coverageIndex(30), 2);
      expect(cov.coverageIndex(50), 4);

      expect(cov.coverageIndex(5), isNull);
      expect(cov.coverageIndex(25), isNull);
      expect(cov.coverageIndex(55), isNull);

      expect(cov.covers(20), isTrue);
      expect(cov.covers(21), isFalse);
    });

    test('Coverage Format 2 range records binary search and index offset calculation', () {
      final cov = CoverageFormat2([
        CoverageRangeRecord(startGlyphId: 10, endGlyphId: 15, startCoverageIndex: 0),
        CoverageRangeRecord(startGlyphId: 30, endGlyphId: 32, startCoverageIndex: 6),
      ]);

      expect(cov.coverageIndex(10), 0);
      expect(cov.coverageIndex(12), 2);
      expect(cov.coverageIndex(15), 5);

      expect(cov.coverageIndex(30), 6);
      expect(cov.coverageIndex(31), 7);
      expect(cov.coverageIndex(32), 8);

      expect(cov.coverageIndex(9), isNull);
      expect(cov.coverageIndex(16), isNull);
      expect(cov.coverageIndex(29), isNull);
      expect(cov.coverageIndex(33), isNull);

      expect(cov.covers(31), isTrue);
      expect(cov.covers(20), isFalse);
    });
  });
}
