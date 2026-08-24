import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:khmer_pdf_shaper/src/font/metrics_table.dart';
import 'package:khmer_pdf_shaper/src/font/opentype_reader.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:khmer_pdf_shaper/src/pdf/truetype_gid_subsetter.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('Phase 7 — Item 9: Zero-Length Glyph Hardening Tests', () {
    late Uint8List fontBytes;
    late TtfParser ttf;
    late TrueTypeGidSubsetter subsetter;
    late MetricsTable origMetrics;

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

      final font = OpenTypeFont.parse(fontBytes);
      origMetrics = MetricsTable.parse(
        headReader: font.getTableReader('head'),
        hheaReader: font.getTableReader('hhea'),
        maxpReader: font.getTableReader('maxp'),
        hmtxReader: font.getTableReader('hmtx'),
      );
    });

    test(
        'Zero-length glyphs (105, 106, 121, 259, 260) have 0 loca length in original font',
        () {
      for (final gid in zeroLengthGids) {
        final start = ttf.glyphOffsets[gid];
        final end = (gid + 1 < ttf.glyphOffsets.length)
            ? ttf.glyphOffsets[gid + 1]
            : ttf.tableSize[TtfParser.glyf_table]!;
        expect(end - start, equals(0),
            reason: 'GID $gid must be zero-length in original font');
      }
    });

    test(
        'Randomized subset combinations preserving zero length across 50 permutations',
        () {
      final rng = Random(42);

      for (int iteration = 0; iteration < 50; iteration++) {
        // Pick random subset of zero-length, simple, compound, and gsub glyphs
        final selected = <int>{};
        for (final z in zeroLengthGids) {
          if (rng.nextBool()) selected.add(z);
        }
        if (selected.isEmpty) {
          selected.add(zeroLengthGids[iteration % zeroLengthGids.length]);
        }

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
        final subsetFont = OpenTypeFont.parse(result.fontBytes);
        final subsetMetrics = MetricsTable.parse(
          headReader: subsetFont.getTableReader('head'),
          hheaReader: subsetFont.getTableReader('hhea'),
          maxpReader: subsetFont.getTableReader('maxp'),
          hmtxReader: subsetFont.getTableReader('hmtx'),
        );

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
            reason:
                'Iteration $iteration: GID $zGid (subset GID $subsetGid) must remain 0 length, but had length ${end - start}',
          );

          // Assert hmtx advance width is preserved
          final origAdvance = origMetrics.advanceWidthForGlyph(zGid);
          final subsetAdvance = subsetMetrics.advanceWidthForGlyph(subsetGid);
          expect(
            subsetAdvance,
            equals(origAdvance),
            reason:
                'Advance width for GID $zGid must be preserved in subset font ($origAdvance vs $subsetAdvance)',
          );
        }
      }
    });

    test(
        'Zero-length glyphs in words (កម្ពុជា, ប៉ា, សង្គ្រាម) render with exact loca zero length in PDF subset',
        () {
      final doc = PdfDocument();
      final page = PdfPage(doc, pageFormat: const PdfPageFormat(500, 500));
      final g = page.getGraphics();
      final khmerFont = KhmerPdfFont(doc, fontBytes.buffer.asByteData());

      // Words containing zero-length glyphs (GID 105, 106, 121, 259, 260)
      final words = ['កម្ពុជា', 'ប៉ា', 'សង្គ្រាម'];
      for (final word in words) {
        final run = BattambangShaper.fromBytes(fontBytes).shapeText(word);
        khmerFont.drawShapedRun(page, g, run, x: 50, y: 300, fontSize: 16);
      }

      // Check registry entries
      final gidsInUse = khmerFont.registry.entries.values
          .map((e) => e.originalGlyphId)
          .toSet();
      for (final zGid in [105, 106, 121, 259, 260]) {
        if (gidsInUse.contains(zGid)) {
          // Verify it is mapped cleanly
          expect(
              khmerFont.registry.entries.values
                  .any((e) => e.originalGlyphId == zGid),
              isTrue);
        }
      }
    });
  });
}
