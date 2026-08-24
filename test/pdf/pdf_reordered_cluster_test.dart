import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:tamil_pdf_shaper/src/pdf/khmer_cid_registry.dart';
import 'package:tamil_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:tamil_pdf_shaper/src/pdf/khmer_tounicode_cmap.dart';
import 'package:tamil_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('Reordered-Cluster ToUnicode Ownership Regression Tests', () {
    late Uint8List fontBytes;
    late BattambangShaper shaper;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
    });

    test('Cluster ownership for ក្រ (reordered pre-base subscript Ro)', () {
      const text = 'ក្រ'; // U+1780 U+17D2 U+179A
      final run = shaper.shapeText(text);

      expect(run.clusters.length, equals(1));
      final cluster = run.clusters.first;

      // Semantic cluster covers full original source range [0..3]
      expect(cluster.sourceStart, equals(0));
      expect(cluster.sourceEnd, equals(3));
      final semanticText = text.substring(cluster.sourceStart, cluster.sourceEnd);
      expect(semanticText, equals('ក្រ'));

      // 2 visual glyphs produced in reordered visual sequence:
      // Visual Glyph 0: Subscript Ro (GID 205) positioned visually before base
      // Visual Glyph 1: Base Consonant Ka (GID 53)
      expect(cluster.glyphs.length, equals(2));
      expect(cluster.glyphs[0].glyphId, equals(205));
      expect(cluster.glyphs[0].sourceStart, equals(1));
      expect(cluster.glyphs[0].sourceEnd, equals(3));
      expect(cluster.glyphs[0].cluster, equals(0));

      expect(cluster.glyphs[1].glyphId, equals(53));
      expect(cluster.glyphs[1].sourceStart, equals(0));
      expect(cluster.glyphs[1].sourceEnd, equals(1));
      expect(cluster.glyphs[1].cluster, equals(0));

      // Simulate ToUnicode allocation
      final registry = KhmerCidRegistry();
      final c0 = registry.allocate(
        originalGlyphId: cluster.glyphs[0].glyphId,
        subsetGlyphId: 1,
        unicodeText: semanticText, // Primary visual glyph receives full cluster Unicode
      );
      final c1 = registry.allocate(
        originalGlyphId: cluster.glyphs[1].glyphId,
        subsetGlyphId: 2,
        unicodeText: '', // Secondary visual glyph receives empty string
      );

      expect(c0.cid, equals(1));
      expect(c0.unicodeText, equals('ក្រ'));
      expect(c1.cid, equals(2));
      expect(c1.unicodeText, equals(''));

      // Verify CMap emission
      final doc = PdfDocument();
      final cmap = KhmerToUnicodeCmap(doc, cidToUnicode: {
        c0.cid: c0.unicodeText,
        c1.cid: c1.unicodeText,
      });
      cmap.prepare();
      final cmapStream = utf8.decode(cmap.buf.output());
      expect(cmapStream, contains('<0001> <178017D2179A>'));
      expect(cmapStream, contains('<0002> <>'));
    });

    test('Cluster ownership for គ្រែ (pre-base vowel + pre-base subscript Ro)', () {
      const text = 'គ្រែ'; // U+1782 U+17D2 U+179A U+17C2
      final run = shaper.shapeText(text);

      expect(run.clusters.length, equals(1));
      final cluster = run.clusters.first;

      expect(cluster.sourceStart, equals(0));
      expect(cluster.sourceEnd, equals(4));
      final semanticText = text.substring(cluster.sourceStart, cluster.sourceEnd);
      expect(semanticText, equals('គ្រែ'));

      // 3 visual glyphs: Vowel Ae (GID 111), Subscript Ro (GID 205), Base Kho (GID 55)
      expect(cluster.glyphs.length, equals(3));
      expect(cluster.glyphs[0].glyphId, equals(111)); // Vowel Ae (source 3..4)
      expect(cluster.glyphs[1].glyphId, equals(205)); // Subscript Ro (source 1..3)
      expect(cluster.glyphs[2].glyphId, equals(55));  // Base Kho (source 0..1)

      final registry = KhmerCidRegistry();
      final c0 = registry.allocate(
        originalGlyphId: cluster.glyphs[0].glyphId,
        subsetGlyphId: 1,
        unicodeText: semanticText, // Primary receives complete cluster
      );
      final c1 = registry.allocate(
        originalGlyphId: cluster.glyphs[1].glyphId,
        subsetGlyphId: 2,
        unicodeText: '',
      );
      final c2 = registry.allocate(
        originalGlyphId: cluster.glyphs[2].glyphId,
        subsetGlyphId: 3,
        unicodeText: '',
      );

      expect(c0.unicodeText, equals('គ្រែ'));
      expect(c1.unicodeText, equals(''));
      expect(c2.unicodeText, equals(''));
    });

    test('Cluster ownership for ខ្ញុំ (complex cluster: base + coeng Nyo + vowel U + Anusvara)', () {
      const text = 'ខ្ញុំ'; // U+1781 U+17D2 U+1789 U+17BB U+17C6
      final run = shaper.shapeText(text);

      expect(run.clusters.length, equals(1));
      final cluster = run.clusters.first;

      expect(cluster.sourceStart, equals(0));
      expect(cluster.sourceEnd, equals(5));
      final semanticText = text.substring(cluster.sourceStart, cluster.sourceEnd);
      expect(semanticText, equals('ខ្ញុំ'));

      // 4 visual glyphs: Base Kha (54), Subscript Nyo (302), Vowel U (329), Nikahit (284)
      expect(cluster.glyphs.length, equals(4));
      expect(cluster.glyphs[0].glyphId, equals(54));
      expect(cluster.glyphs[1].glyphId, equals(302));
      expect(cluster.glyphs[2].glyphId, equals(329));
      expect(cluster.glyphs[3].glyphId, equals(284));

      final registry = KhmerCidRegistry();
      final c0 = registry.allocate(
        originalGlyphId: cluster.glyphs[0].glyphId,
        subsetGlyphId: 1,
        unicodeText: semanticText,
      );
      final c1 = registry.allocate(
        originalGlyphId: cluster.glyphs[1].glyphId,
        subsetGlyphId: 2,
        unicodeText: '',
      );

      expect(c0.unicodeText, equals('ខ្ញុំ'));
      expect(c1.unicodeText, equals(''));
    });

    test('Cluster ownership for multi-syllable word សួស្តី (2 syllables: សួ + ស្តី)', () {
      const text = 'សួស្តី'; // U+179F U+17BD + U+179F U+17D2 U+178F U+17B8
      final run = shaper.shapeText(text);

      expect(run.clusters.length, equals(2));

      // Syllable 1: សួ (0..2)
      final c1 = run.clusters[0];
      expect(c1.sourceStart, equals(0));
      expect(c1.sourceEnd, equals(2));
      expect(text.substring(c1.sourceStart, c1.sourceEnd), equals('សួ'));
      expect(c1.glyphs.length, equals(2)); // Sa (84), Vowel Ua (282)

      // Syllable 2: ស្តី (2..6)
      final c2 = run.clusters[1];
      expect(c2.sourceStart, equals(2));
      expect(c2.sourceEnd, equals(6));
      expect(text.substring(c2.sourceStart, c2.sourceEnd), equals('ស្តី'));
      expect(c2.glyphs.length, equals(3)); // Sa (84), Coeng Ta (307), Vowel Ii (277)

      // End-to-end PDF rendering verification
      final doc = PdfDocument();
      final page = PdfPage(doc, pageFormat: const PdfPageFormat(500, 500));
      final g = page.getGraphics();
      final font = KhmerPdfFont(doc, fontBytes.buffer.asByteData());

      font.drawShapedRun(page, g, run, x: 50, y: 400, fontSize: 16);

      final entrySa1 = font.registry.entries.values.firstWhere((e) => e.unicodeText == 'សួ');
      final entrySa2 = font.registry.entries.values.firstWhere((e) => e.unicodeText == 'ស្តី');
      expect(entrySa1, isNotNull);
      expect(entrySa2, isNotNull);
      // Even though both syllables start with base glyph GID 84, each gets its own unique CID mapping
      expect(entrySa1.cid, isNot(equals(entrySa2.cid)));
    });
  });
}
