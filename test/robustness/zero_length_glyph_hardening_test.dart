import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:khmer_pdf_shaper/src/pdf/truetype_gid_subsetter.dart';

void main() {
  group('Phase 7 — Item 9: Zero-Length Glyph Hardening Tests', () {
    late Uint8List fontBytes;
    late TtfParser ttf;
    late TrueTypeGidSubsetter subsetter;

    const zeroLengthGids = [105, 106, 121, 259, 260];
    const simpleGids = [3, 4, 5, 53, 54, 55, 60, 70, 80];
    const compoundGids = [332, 335, 347, 350];
    const gsubGids = [150, 160, 200, 210, 270, 280];

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      ttf = TtfParser(fontBytes.buffer.asByteData());
      subsetter = TrueTypeGidSubsetter(ttf);
    });

    test('Zero-length glyphs (105, 106, 121, 259, 260) have 0 loca length in original font', () {
      for (final gid in zeroLengthGids) {
        final start = ttf.glyphOffsets[gid];
        final end = (gid + 1 < ttf.glyphOffsets.length)
            ? ttf.glyphOffsets[gid + 1]
            : ttf.tableSize[TtfParser.glyf_table]!;
        expect(end - start, equals(0), reason: 'GID $gid must be zero-length in original font');
      }
    });

    test('Randomized subset combinations preserving zero length across 50 permutations', () {
      final rng = Random(42);

      for (int iteration = 0; iteration < 50; iteration++) {
        // Pick random subset of zero-length, simple, compound, and gsub glyphs
        final selected = <int>{};
        for (final z in zeroLengthGids) {
          if (rng.nextBool()) selected.add(z);
        }
        if (selected.isEmpty) selected.add(zeroLengthGids[iteration % zeroLengthGids.length]);

        for (final s in simpleGids) {
          if (rng.nextBool()) selected.add(s);
        }
        for (final c in compoundGids) {
          if (rng.nextBool()) selected.add(c);
        }
        for (final g in gsubGids) {
          if (rng.nextBool()) selected.add(g);
        }

        final result = subsetter.subsetGlyphs(selected);
        final parsed = TtfParser(result.fontBytes.buffer.asByteData());

        for (final zGid in zeroLengthGids) {
          if (!result.originalToSubset.containsKey(zGid)) continue;
          final subsetGid = result.originalToSubset[zGid]!;
          final start = parsed.glyphOffsets[subsetGid];
          final end = (subsetGid + 1 < parsed.glyphOffsets.length)
              ? parsed.glyphOffsets[subsetGid + 1]
              : parsed.tableSize[TtfParser.glyf_table]!;

          expect(
            end - start,
            equals(0),
            reason: 'Iteration $iteration: GID $zGid (subset GID $subsetGid) must remain 0 length, but had length ${end - start}',
          );
        }
      }
    });
  });
}
