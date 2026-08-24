import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_pdf_shaper/src/font/opentype_reader.dart';
import 'package:tamil_pdf_shaper/src/gsub/gsub_evaluator.dart';

void main() {
  group('Part 12 & 13: GSUB Lookup Flags & GDEF Decision Tests', () {
    late GsubTable gsub;

    setUpAll(() {
      final fontBytes = File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
      final font = OpenTypeFont.parse(fontBytes);
      gsub = GsubTable.parse(font.getTableReader('GSUB'));
    });

    test('All 29 lookups in Battambang-Regular.ttf have LookupFlag = 0', () {
      expect(gsub.lookups.length, 29);
      for (int i = 0; i < gsub.lookups.length; i++) {
        final flag = gsub.lookups[i].lookupFlag;
        expect(
          flag,
          0,
          reason: 'Lookup $i in Battambang-Regular.ttf must have LookupFlag 0, but was $flag',
        );
      }
    });

    test('GDEF Decision: GDEF parsing is not required in v1 due to zero lookup flags', () {
      // Documenting invariant:
      // None of the lookups in Battambang-Regular.ttf rely on IgnoreBaseGlyphs,
      // IgnoreLigatures, IgnoreMarks, UseMarkFilteringSet, or MarkAttachmentType.
      // Therefore, GDEF glyph class parsing is safely omitted from Phase 3 v1.
      final hasNonZeroFlags = gsub.lookups.any((l) => l.lookupFlag != 0);
      expect(hasNonZeroFlags, isFalse);
    });
  });
}
