import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:khmer_pdf_shaper/src/pdf/truetype_gid_subsetter.dart';

void main() {
  group('TrueType GID Subsetting Tests', () {
    late Uint8List fontBytes;
    late TtfParser ttf;
    late TrueTypeGidSubsetter subsetter;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      ttf = TtfParser(fontBytes.buffer.asByteData());
      subsetter = TrueTypeGidSubsetter(ttf);
    });

    test('Always includes GID 0 (.notdef) in subset font', () {
      final result = subsetter.subsetGlyphs([53, 205]);
      expect(result.originalToSubset.containsKey(0), isTrue);
      expect(result.originalToSubset[0], equals(0));
      expect(result.subsetToOriginal[0], equals(0));

      final parsed = TtfParser(result.fontBytes.buffer.asByteData());
      expect(parsed.glyphOffsets.length, equals(3)); // GID 0, 53, 205
    });

    test(
        'Recursively resolves compound glyph dependencies (e.g. GID 332 depends on 280)',
        () {
      // Original font GID 332 is a compound glyph referencing GID 280
      final origGlyph332 = ttf.readGlyph(332);
      expect(origGlyph332.compounds, contains(280));

      // Request only GID 332
      final result = subsetter.subsetGlyphs([332]);

      // Result must automatically include 280
      expect(result.originalToSubset.containsKey(280), isTrue);
      expect(result.originalToSubset.containsKey(332), isTrue);

      final subsetGid280 = result.originalToSubset[280]!;
      final subsetGid332 = result.originalToSubset[332]!;

      // Parse subset font and verify the remapped compound reference inside glyph 332
      final parsed = TtfParser(result.fontBytes.buffer.asByteData());
      final parsedGlyph332 = parsed.readGlyph(subsetGid332);
      expect(parsedGlyph332.compounds, contains(subsetGid280));
    });

    test('Resolves multiple compound dependencies (335 -> 329, 347 -> 303)',
        () {
      final result = subsetter.subsetGlyphs([335, 347]);
      expect(result.originalToSubset.containsKey(329), isTrue);
      expect(result.originalToSubset.containsKey(303), isTrue);

      final parsed = TtfParser(result.fontBytes.buffer.asByteData());
      expect(parsed.glyphOffsets.length, equals(5)); // 0, 303, 329, 335, 347
    });

    test(
        'Produces valid TrueType font binary parseable by TtfParser with correct metrics',
        () {
      final requested = [
        53,
        54,
        55,
        77,
        84,
        110,
        111,
        121,
        122,
        130,
        136,
        162,
        205,
        207,
        277,
        282,
        284,
        285,
        295,
        297,
        302,
        307,
        313,
        329
      ];
      final result = subsetter.subsetGlyphs(requested);

      expect(result.fontBytes.length, isPositive);
      expect(result.fontBytes.length, lessThan(fontBytes.length ~/ 2));

      final parsed = TtfParser(result.fontBytes.buffer.asByteData());
      expect(parsed.fontName, isNotEmpty);
      expect(parsed.unitsPerEm, equals(2048));
      expect(parsed.glyphOffsets.length,
          equals(requested.length + 1)); // +1 for GID 0
    });

    test(
        'Correctly preserves zero-length spacing glyphs (GID 105, 106, 121, 259, 260) without ghost contours',
        () {
      const zeroLengthGids = [105, 106, 121, 259, 260];
      const expectedAdvances = {
        105: 1204,
        106: 1204,
        121: 610,
        259: 700,
        260: 700,
      };

      // 1. Test each zero-length glyph individually
      for (final gid in zeroLengthGids) {
        final result = subsetter.subsetGlyphs([gid]);
        final subsetGid = result.originalToSubset[gid]!;
        final parsed = TtfParser(result.fontBytes.buffer.asByteData());

        // In the subset font's loca table, glyph length must be 0
        final start = parsed.glyphOffsets[subsetGid];
        final end = (subsetGid + 1 < parsed.glyphOffsets.length)
            ? parsed.glyphOffsets[subsetGid + 1]
            : parsed.tableSize[TtfParser.glyf_table]!;
        expect(end - start, equals(0),
            reason: 'GID $gid must have zero length in loca table');

        // Must preserve hmtx advance width and LSB
        final hmtxOffset = parsed.tableOffsets[TtfParser.hmtx_table]!;
        final hmtxData = parsed.bytes.buffer.asByteData(
          hmtxOffset,
          parsed.tableSize[TtfParser.hmtx_table]!,
        );
        final adv = hmtxData.getUint16(subsetGid * 4);
        final lsb = hmtxData.getInt16(subsetGid * 4 + 2);
        expect(adv, equals(expectedAdvances[gid]),
            reason: 'GID $gid advance width mismatch');
        expect(lsb, equals(0), reason: 'GID $gid LSB mismatch');
      }

      // 2. Test all zero-length glyphs together with normal and compound glyphs
      final allTogether = subsetter.subsetGlyphs([...zeroLengthGids, 53, 332]);
      final parsedAll = TtfParser(allTogether.fontBytes.buffer.asByteData());

      for (final gid in zeroLengthGids) {
        final subsetGid = allTogether.originalToSubset[gid]!;
        final start = parsedAll.glyphOffsets[subsetGid];
        final end = (subsetGid + 1 < parsedAll.glyphOffsets.length)
            ? parsedAll.glyphOffsets[subsetGid + 1]
            : parsedAll.tableSize[TtfParser.glyf_table]!;
        expect(end - start, equals(0),
            reason:
                'Collective subset: GID $gid must have zero length in loca table');

        final hmtxOffset = parsedAll.tableOffsets[TtfParser.hmtx_table]!;
        final hmtxData = parsedAll.bytes.buffer.asByteData(
          hmtxOffset,
          parsedAll.tableSize[TtfParser.hmtx_table]!,
        );
        final adv = hmtxData.getUint16(subsetGid * 4);
        expect(adv, equals(expectedAdvances[gid]));
      }
    });
  });
}
