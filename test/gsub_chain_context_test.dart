import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/gsub/coverage_table.dart';
import 'package:khmer_pdf_shaper/src/gsub/gsub_tables.dart';

void main() {
  group('Part 9: GSUB Type 6 Format 3 ChainContextSubst Tests', () {
    test('Matches backtrack, input, and lookahead coverage sequences correctly', () {
      final backtrackCov = [CoverageFormat1([10])];
      final inputCov = [CoverageFormat1([20])];
      final lookaheadCov = [CoverageFormat1([30])];

      final chain = ChainContextSubstFormat3(
        backtrackCoverages: backtrackCov,
        inputCoverages: inputCov,
        lookaheadCoverages: lookaheadCov,
        substLookupRecords: [
          const SubstLookupRecord(sequenceIndex: 0, lookupListIndex: 99),
        ],
      );

      final buffer = [
        ShapingGlyph(glyphId: 10, cluster: 0, sourceStart: 0, sourceEnd: 1),
        ShapingGlyph(glyphId: 20, cluster: 1, sourceStart: 1, sourceEnd: 2),
        ShapingGlyph(glyphId: 30, cluster: 2, sourceStart: 2, sourceEnd: 3),
      ];

      // At position 1: backtrack is [10], input is [20], lookahead is [30] -> matches!
      int appliedLookup = -1;
      int appliedPos = -1;
      final applied = chain.apply(buffer, 1, (idx, buf, pos) {
        appliedLookup = idx;
        appliedPos = pos;
        buf[pos].glyphId = 200;
        return true;
      });

      expect(applied, isTrue);
      expect(appliedLookup, 99);
      expect(appliedPos, 1);
      expect(buffer[1].glyphId, 200);

      // At position 0: no backtrack -> fails
      expect(chain.apply(buffer, 0, (idx, buf, pos) => false), isFalse);
    });
  });
}
