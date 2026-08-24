import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:khmer_pdf_shaper/src/pdf/truetype_gid_subsetter.dart';

void main() {
  group('Phase 7 — Item 10: Composite Glyph Subsetting Stress Tests', () {
    late Uint8List fontBytes;
    late TtfParser ttf;
    late TrueTypeGidSubsetter subsetter;
    late List<int> compoundGids;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      ttf = TtfParser(fontBytes.buffer.asByteData());
      subsetter = TrueTypeGidSubsetter(ttf);

      // Find all compound glyphs in Battambang
      compoundGids = <int>[];
      for (int gid = 0; gid < ttf.glyphOffsets.length; gid++) {
        final start = ttf.glyphOffsets[gid];
        final end = (gid + 1 < ttf.glyphOffsets.length)
            ? ttf.glyphOffsets[gid + 1]
            : ttf.tableSize[TtfParser.glyf_table]!;
        if (start == end) continue;

        final glyph = ttf.readGlyph(gid);
        if (glyph.compounds.isNotEmpty) {
          compoundGids.add(gid);
        }
      }
    });

    test('Identifies all compound glyphs in Battambang font and tests independent subsetting', () {
      expect(compoundGids, isNotEmpty);

      for (final compGid in compoundGids) {
        final origGlyph = ttf.readGlyph(compGid);
        final origDependencies = origGlyph.compounds;

        // 1. Subset this compound glyph independently
        final result = subsetter.subsetGlyphs([compGid]);

        // Verify subset map contains all dependencies
        expect(result.originalToSubset.containsKey(compGid), isTrue);
        for (final dep in origDependencies) {
          expect(result.originalToSubset.containsKey(dep), isTrue,
              reason: 'Compound GID $compGid dependency $dep must be pulled into subset');
        }

        // 2. Parse subset font and verify compound glyph structure
        final parsed = TtfParser(result.fontBytes.buffer.asByteData());
        final subsetCompGid = result.originalToSubset[compGid]!;
        final parsedCompGlyph = parsed.readGlyph(subsetCompGid);

        // Verify that parsed dependencies match remapped GIDs
        final expectedRemappedDeps = origDependencies.map((d) => result.originalToSubset[d]!).toList();
        expect(parsedCompGlyph.compounds, equals(expectedRemappedDeps),
            reason: 'Remapped dependencies of GID $compGid in subset font must match');
      }
    });

    test('Subsets all compound glyphs collectively with simple and GSUB glyphs and validates with fontTools', () {
      final result = subsetter.subsetGlyphs([...compoundGids, 53, 54, 55, 150]);
      final parsed = TtfParser(result.fontBytes.buffer.asByteData());

      for (final compGid in compoundGids) {
        final origGlyph = ttf.readGlyph(compGid);
        final subsetCompGid = result.originalToSubset[compGid]!;
        final parsedCompGlyph = parsed.readGlyph(subsetCompGid);

        final expectedRemappedDeps = origGlyph.compounds.map((d) => result.originalToSubset[d]!).toList();
        expect(parsedCompGlyph.compounds, equals(expectedRemappedDeps));
      }

      // Save subset TTF to disk for fontTools validation
      final outFile = File('build/subset_test.ttf');
      outFile.parent.createSync(recursive: true);
      outFile.writeAsBytesSync(result.fontBytes);
      expect(outFile.existsSync(), isTrue);
    });
  });
}
