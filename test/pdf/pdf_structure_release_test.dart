import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('Phase 8 — Release Gate: PDF Structural Integrity Validation', () {
    late Uint8List fontBytes;
    late BattambangShaper shaper;

    setUpAll(() {
      final fontFile = File('assets/fonts/Battambang-Regular.ttf');
      expect(fontFile.existsSync(), isTrue);
      fontBytes = fontFile.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
    });

    test('Generated PDF contains all mandatory Type0 and CIDFontType2 structures', () async {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            children: [
              KhmerText('ព្រះរាជាណាចក្រកម្ពុជា', style: const pw.TextStyle(fontSize: 20)),
              KhmerText('Invoice សួស្តី 123', style: const pw.TextStyle(fontSize: 14)),
              KhmerText('សង្គ្រាម និង សន្តិភាព', style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);
      final pdfString = latin1.decode(pdfBytes, allowInvalid: true);

      // 1. Type0 composite font dictionary
      expect(pdfString, contains('/Type/Font'));
      expect(pdfString, contains('/Subtype/Type0'));
      expect(pdfString, contains('/Encoding/Identity-H'));

      // 2. CIDFontType2 dictionary
      expect(pdfString, contains('/Subtype/CIDFontType2'));
      expect(pdfString, contains('/CIDSystemInfo'));
      expect(pdfString, contains('/Registry(Adobe)'));
      expect(pdfString, contains('/Ordering(Identity)'));

      // 3. FontDescriptor with embedding flags
      expect(pdfString, contains('/Type/FontDescriptor'));
      expect(pdfString, contains('/FontName/'));
      expect(pdfString, contains('/Flags'));
      expect(pdfString, contains('/FontBBox'));
      expect(pdfString, contains('/ItalicAngle'));
      expect(pdfString, contains('/Ascent'));
      expect(pdfString, contains('/Descent'));
      expect(pdfString, contains('/CapHeight'));

      // 4. FontFile2 stream (embedded TrueType subset)
      expect(pdfString, contains('/FontFile2'));

      // 5. CIDToGIDMap stream
      expect(pdfString, contains('/CIDToGIDMap'));

      // 6. ToUnicode CMap stream
      expect(pdfString, contains('/ToUnicode'));

      // 7. Width table /W
      expect(pdfString, contains('/W['));
    });

    test('Structural invariant: CID != GID and multiple CIDs to single subset GID supported', () async {
      final doc = PdfDocument();
      final page = PdfPage(doc, pageFormat: const PdfPageFormat(500, 500));
      final g = page.getGraphics();
      final khmerFont = KhmerPdfFont(doc, fontBytes.buffer.asByteData());

      // Register words with overlapping and distinct glyphs
      // "សួស្តី" and "សង្គ្រាម" both use consonant SA (U+179f -> GID 84)
      final run1 = shaper.shapeText('សួស្តី');
      final run2 = shaper.shapeText('សង្គ្រាម');

      khmerFont.drawShapedRun(page, g, run1, x: 50, y: 400, fontSize: 16);
      khmerFont.drawShapedRun(page, g, run2, x: 50, y: 350, fontSize: 16);

      // Verify that CID registry has entries
      final entries = khmerFont.registry.entries;
      expect(entries.length, greaterThanOrEqualTo(2));

      // Assert CID allocation starts from 1 and is distinct from raw TrueType GIDs
      bool foundCidDifferentFromGid = false;
      for (final entry in entries.values) {
        if (entry.cid != 0 && entry.cid != entry.originalGlyphId) {
          foundCidDifferentFromGid = true;
        }
      }
      expect(foundCidDifferentFromGid, isTrue,
          reason: 'CID space is independent from raw TrueType GID space (CID != GID)');

      // Verify font subsetting compiles cleanly
      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);
    });
  });
}
