import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:khmer_pdf_shaper/src/font/cmap_table.dart';
import 'package:khmer_pdf_shaper/src/font/opentype_reader.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_cid_to_gid_stream.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_font_cache.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_pdf_font.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_tounicode_cmap.dart';
import 'package:khmer_pdf_shaper/src/pdf/truetype_gid_subsetter.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';
import 'package:khmer_pdf_shaper/src/shaper/shaped_run.dart';
import 'package:khmer_pdf_shaper/src/widgets/khmer_text.dart';
import 'package:pdf/pdf.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/font/ttf_parser.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/array.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/dict.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/num.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/string.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/obj/font_descriptor.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/obj/object.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/obj/object_stream.dart';
import 'package:pdf/widgets.dart' as pw;

/// Diagnostic Full-Font KhmerPdfFont that embeds the entire original TTF
/// without subsetting, mapping CID directly to original GID.
class DiagnosticFullKhmerPdfFont extends PdfFont {
  final TtfParser font;
  final ByteData _rawBytes;
  final Set<int> _usedOriginalGids = <int>{0};

  late final PdfObjectStream _file;
  late final PdfFontDescriptor _descriptor;
  late final PdfObject<PdfArray> _widthsObject;
  late final KhmerCidToGidStream _cidToGidStream;
  late final KhmerToUnicodeCmap _toUnicodeCmap;

  final Map<int, int> _cidToSubsetGid = <int, int>{};
  final Map<int, String> _cidToUnicode = <int, String>{};
  final Map<int, int> _origGidToCid = <int, int>{};
  int _nextCid = 1;

  DiagnosticFullKhmerPdfFont(super.pdfDocument, ByteData fontBytes)
      : font = TtfParser(fontBytes),
        _rawBytes = fontBytes,
        super.create(subtype: '/Type0') {
    _file = PdfObjectStream(pdfDocument, isBinary: true);
    final dummyTtf = PdfTtfFont(pdfDocument, fontBytes);
    _descriptor = PdfFontDescriptor(dummyTtf, _file);
    _widthsObject = PdfObject<PdfArray>(pdfDocument, params: PdfArray());
    _cidToGidStream = KhmerCidToGidStream(
      pdfDocument,
      cidToSubsetGid: _cidToSubsetGid,
    );
    _toUnicodeCmap = KhmerToUnicodeCmap(
      pdfDocument,
      cidToUnicode: _cidToUnicode,
    );
    _cidToSubsetGid[0] = 0;
    _cidToUnicode[0] = '';
  }

  @override
  String get fontName => font.fontName;
  @override
  double get ascent => font.ascent.toDouble() / font.unitsPerEm;
  @override
  double get descent => font.descent.toDouble() / font.unitsPerEm;
  @override
  int get unitsPerEm => font.unitsPerEm;

  int nominalDesignWidth(int origGid) {
    if (origGid >= font.glyphOffsets.length) return 0;
    final hmtxOffset = font.tableOffsets[TtfParser.hmtx_table]!;
    final origHmtx = font.bytes.buffer
        .asByteData(hmtxOffset, font.tableSize[TtfParser.hmtx_table]!);
    final numLongMetrics = font.numOfLongHorMetrics;
    if (origGid < numLongMetrics) {
      return origHmtx.getUint16(origGid * 4);
    } else {
      return origHmtx.getUint16((numLongMetrics - 1) * 4);
    }
  }

  @override
  PdfFontMetrics glyphMetrics(int charCode) =>
      font.glyphInfoMap[charCode] ?? PdfFontMetrics.zero;
  @override
  bool isRuneSupported(int charCode) => true;

  void drawShapedRun(
    PdfPage page,
    PdfGraphics graphics,
    ShapedRun run, {
    required double x,
    required double y,
    required double fontSize,
  }) {
    page.altered = true;
    final stream = (page.contents.last as PdfObjectStream).buf;

    final cids = <int>[];
    for (final cluster in run.clusters) {
      final clusterText =
          run.originalText.substring(cluster.sourceStart, cluster.sourceEnd);
      for (int i = 0; i < cluster.glyphs.length; i++) {
        final g = run.glyphs[i];
        _usedOriginalGids.add(g.glyphId);
        int cid = _origGidToCid[g.glyphId] ?? 0;
        if (cid == 0) {
          cid = _nextCid++;
          _origGidToCid[g.glyphId] = cid;
          _cidToSubsetGid[cid] = g.glyphId; // Direct original GID
          _cidToUnicode[cid] = (i == 0) ? clusterText : '';
        }
        cids.add(cid);
      }
    }

    graphics.setFont(this, fontSize);
    stream.putString('BT\n');
    stream.putString('$name $fontSize Tf\n');
    stream.putString('$x $y Td\n');
    stream.putString('[');

    for (int i = 0; i < run.glyphs.length; i++) {
      final g = run.glyphs[i];
      final cid = cids[i];
      final cidHex = cid.toRadixString(16).toUpperCase().padLeft(4, '0');
      stream.putString('<$cidHex>');

      final nomDesign = nominalDesignWidth(g.glyphId);
      final shapedDesign = g.xAdvance.round();
      final diff = nomDesign - shapedDesign;
      if (diff != 0) {
        final adj = (diff * 1000.0 / unitsPerEm).round();
        stream.putString(' $adj ');
      }
    }

    stream.putString('] TJ\n');
    stream.putString('ET\n');
  }

  @override
  void prepare() {
    super.prepare();
    final fullBytes = _rawBytes.buffer
        .asUint8List(_rawBytes.offsetInBytes, _rawBytes.lengthInBytes);
    _file.buf.putBytes(fullBytes);
    _file.params['/Length1'] = PdfNum(fullBytes.length);

    _widthsObject.params.values.clear();
    for (int cid = 0; cid < _nextCid; cid++) {
      final origGid = _cidToSubsetGid[cid] ?? 0;
      final nomWidth =
          (nominalDesignWidth(origGid) * 1000.0 / unitsPerEm).round();
      _widthsObject.params.add(PdfNum(nomWidth));
    }

    final descendantFont = PdfDict.values({
      '/Type': const PdfName('/Font'),
      '/BaseFont': PdfName('/$fontName'),
      '/FontFile2': _file.ref(),
      '/FontDescriptor': _descriptor.ref(),
      '/W': PdfArray([const PdfNum(0), _widthsObject.ref()]),
      '/CIDToGIDMap': _cidToGidStream.ref(),
      '/DW': const PdfNum(1000),
      '/Subtype': const PdfName('/CIDFontType2'),
      '/CIDSystemInfo': PdfDict.values({
        '/Supplement': const PdfNum(0),
        '/Registry': PdfString.fromString('Adobe'),
        '/Ordering': PdfString.fromString('Identity'),
      }),
    });

    params['/BaseFont'] = PdfName('/$fontName');
    params['/Encoding'] = const PdfName('/Identity-H');
    params['/DescendantFonts'] = PdfArray([descendantFont]);
    params['/ToUnicode'] = _toUnicodeCmap.ref();
  }
}

void main() async {
  final fontFile = File('assets/fonts/Battambang-Regular.ttf');
  final fontBytes = await fontFile.readAsBytes();
  final byteData = ByteData.sublistView(fontBytes);
  final shaper = BattambangShaper.fromBytes(fontBytes);

  final testWords = [
    'សួស្តី',
    'កម្ពុជា',
    'ខ្ញុំ',
    'សង្គ្រាម',
    'ក្រ',
    'ក្ក',
    'គ្រែ',
    'ប៉ា',
  ];

  final exampleStrings = [
    'ព្រះរាជាណាចក្រកម្ពុជា',
    'ជាតិ សាសនា ព្រះមហាក្សត្រ',
    'Invoice សួស្តី 123',
    'Price: \$10.50 កម្ពុជា | Total: \$21.00 រៀល',
    'ការពិពណ៌នា៖ ភាសាខ្មែរ គឺជាភាសាផ្លូវការរបស់ប្រទេសកម្ពុជា ដែលត្រូវបានប្រើប្រាស់ដោយប្រជាជនខ្មែររាប់លាននាក់។ កម្មវិធី Khmer PDF Shaper នេះជួយសម្រួលដល់ការបង្កើតឯកសារ PDF ឲ្យមានសោភ័ណភាពស្រស់ស្អាត ត្រឹមត្រូវតាមក្បួនខ្នាតអក្ខរាវិរុទ្ធខ្មែរ និងអាចស្វែងរក (Search) ឬចម្លង (Copy-Paste) អក្សរបានយ៉ាងរលូន។',
    'តម្រឹមឆ្វេង៖ សួស្តីកម្ពុជា',
    'តម្រឹមកណ្តាល៖ ខ្ញុំស្រឡាញ់ភាសាខ្មែរ',
    'តម្រឹមស្តាំ៖ អរគុណសន្តិភាព',
    'Generated with pure Dart khmer_pdf_shaper',
  ];

  final scratchDir = Directory(
      '/Users/hengmengsroin/.gemini/antigravity-ide/brain/5006973f-44c1-4e4b-919a-7d35886193a5/scratch');
  if (!scratchDir.existsSync()) {
    scratchDir.createSync(recursive: true);
  }

  // --- SECTION 1: CODEPOINTS & UTF-16 LENGTHS ---
  print('=== SECTION 1: CODEPOINTS & UTF-16 LENGTHS ===');
  final allStrings = [...testWords, ...exampleStrings];
  for (final s in allStrings) {
    final codepoints = s.runes
        .map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}')
        .toList();
    print('---');
    print('text: "$s"');
    print('codepoints: [${codepoints.join(', ')}]');
    print('utf16_length: ${s.length}');
  }

  // --- SECTION 5 & 6: EXTRACT SHAPED RUNS & PDF POSITIONING ---
  final Map<String, dynamic> shapedOutput = {};
  for (final s in allStrings) {
    final run = shaper.shapeText(s);
    final glyphsData = <Map<String, dynamic>>[];
    double cursor = 0.0;
    const fontSize = 12.0;
    final unitsPerEm = shaper.metrics.unitsPerEm.toDouble();

    for (int i = 0; i < run.glyphs.length; i++) {
      final g = run.glyphs[i];
      final nomDesign = shaper.metrics.advanceWidthForGlyph(g.glyphId);
      final shapedDesign = g.xAdvance.round();
      final diff = nomDesign - shapedDesign;
      final tjAdj = (diff * 1000.0 / unitsPerEm).round();
      final cursorBefore = cursor;
      final drawPos = cursor + (g.xOffset * fontSize / unitsPerEm);
      final cursorAfter = cursor + (g.xAdvance * fontSize / unitsPerEm);
      cursor = cursorAfter;

      glyphsData.add({
        'glyph_id': g.glyphId,
        'cluster': g.cluster,
        'x_advance': g.xAdvance,
        'y_advance': g.yAdvance,
        'x_offset': g.xOffset,
        'y_offset': g.yOffset,
        'font_units': {
          'nominalWidth': nomDesign,
          'xAdvance': g.xAdvance,
          'xOffset': g.xOffset,
          'yOffset': g.yOffset,
        },
        'pdf_points': {
          'nominal_width': nomDesign * fontSize / unitsPerEm,
          'tj_adjustment': tjAdj,
          'expected_cursor_before': cursorBefore,
          'expected_cursor_after': cursorAfter,
          'actual_draw_position': drawPos,
        }
      });
    }
    shapedOutput[s] = glyphsData;
  }

  final jsonFile = File('${scratchDir.path}/dart_shaped_runs.json');
  await jsonFile
      .writeAsString(const JsonEncoder.withIndent('  ').convert(shapedOutput));
  print('Saved shaped runs to ${jsonFile.path}');

  // --- SECTION 8 & 9: SUBSET FONT FIDELITY ---
  print('\n=== SECTION 9: SUBSET FONT FIDELITY ===');
  final subsetter = TrueTypeGidSubsetter(TtfParser(byteData));
  final allUsedGids = <int>{0};
  for (final s in allStrings) {
    final run = shaper.shapeText(s);
    for (final g in run.glyphs) {
      allUsedGids.add(g.glyphId);
    }
  }
  final subsetResult = subsetter.subsetGlyphs(allUsedGids);
  final subsetTtf = TtfParser(ByteData.sublistView(subsetResult.fontBytes));

  print('Original GIDs count: ${allUsedGids.length}');
  print('Subset GIDs count: ${subsetResult.originalToSubset.length}');

  final fidelityResults = <Map<String, dynamic>>[];
  for (final origGid in allUsedGids) {
    final subsetGid = subsetResult.originalToSubset[origGid]!;
    final origGlyph = TtfParser(byteData).readGlyph(origGid);
    final subGlyph = subsetTtf.readGlyph(subsetGid);

    final origAdv = shaper.metrics.advanceWidthForGlyph(origGid);
    final origLsb = shaper.metrics.leftSideBearingForGlyph(origGid);

    // Read subset hmtx
    final hmtxOff = subsetTtf.tableOffsets[TtfParser.hmtx_table]!;
    final subHmtx = subsetTtf.bytes.buffer
        .asByteData(hmtxOff, subsetTtf.tableSize[TtfParser.hmtx_table]!);
    final subAdv = subHmtx.getUint16(subsetGid * 4);
    final subLsb = subHmtx.getInt16(subsetGid * 4 + 2);

    int origContours = 0;
    int subContours = 0;
    List<int> origBbox = [0, 0, 0, 0];
    List<int> subBbox = [0, 0, 0, 0];

    if (origGlyph.data.lengthInBytes >= 10) {
      final origBd = origGlyph.data.buffer.asByteData(
          origGlyph.data.offsetInBytes, origGlyph.data.lengthInBytes);
      origContours = origBd.getInt16(0);
      origBbox = [
        origBd.getInt16(2),
        origBd.getInt16(4),
        origBd.getInt16(6),
        origBd.getInt16(8)
      ];
    }
    if (subGlyph.data.lengthInBytes >= 10) {
      final subBd = subGlyph.data.buffer
          .asByteData(subGlyph.data.offsetInBytes, subGlyph.data.lengthInBytes);
      subContours = subBd.getInt16(0);
      subBbox = [
        subBd.getInt16(2),
        subBd.getInt16(4),
        subBd.getInt16(6),
        subBd.getInt16(8)
      ];
    }

    final matchesBbox = origBbox[0] == subBbox[0] &&
        origBbox[1] == subBbox[1] &&
        origBbox[2] == subBbox[2] &&
        origBbox[3] == subBbox[3];
    final matchesContours = origContours == subContours;
    final matchesAdv = origAdv == subAdv;
    final matchesLsb = origLsb == subLsb;

    fidelityResults.add({
      'origGid': origGid,
      'subsetGid': subsetGid,
      'bbox': origBbox,
      'contours': origContours,
      'compounds': origGlyph.compounds,
      'adv': origAdv,
      'lsb': origLsb,
      'fidelity_ok': matchesBbox && matchesContours && matchesAdv && matchesLsb,
    });
  }
  final fidelityFile = File('${scratchDir.path}/subset_fidelity.json');
  await fidelityFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(fidelityResults));
  print('Saved subset fidelity report to ${fidelityFile.path}');

  // --- SECTION 10, 11, 12: GENERATE DIAGNOSTIC PDFS ---
  print('\n=== GENERATING DIAGNOSTIC PDFS ===');

  // 1. Generate single-word large size PDFs (48pt, 72pt)
  for (final word in testWords) {
    for (final size in [48.0, 72.0]) {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(500, 200, marginAll: 20),
          build: (context) => pw.Center(
            child: KhmerText(
              word,
              style: pw.TextStyle(fontSize: size),
            ),
          ),
        ),
      );
      final pdfBytes = await doc.save();
      final file = File(
          '${scratchDir.path}/word_${word}_${size.toInt()}pt_khmertext.pdf');
      await file.writeAsBytes(pdfBytes);
    }
  }

  // 2. Generate Phase 4 Direct Drawing vs Phase 5 KhmerText PDFs for all test words
  for (final word in testWords) {
    // Phase 4 Direct
    final docP4 = pw.Document();
    final fontP4 = KhmerPdfFont(docP4.document, byteData);
    final run = shaper.shapeText(word);
    docP4.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(500, 200, marginAll: 20),
        build: (context) => pw.CustomPaint(
          size: const PdfPoint(460, 160),
          painter: (canvas, size) {
            fontP4.drawShapedRun(
              context.page,
              canvas,
              run,
              x: 50,
              y: 80,
              fontSize: 48,
            );
          },
        ),
      ),
    );
    await File('${scratchDir.path}/word_${word}_48pt_phase4.pdf')
        .writeAsBytes(await docP4.save());

    // Phase 4 Direct with Full Font (Path B)
    final docFull = pw.Document();
    final fontFull = DiagnosticFullKhmerPdfFont(docFull.document, byteData);
    docFull.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(500, 200, marginAll: 20),
        build: (context) => pw.CustomPaint(
          size: const PdfPoint(460, 160),
          painter: (canvas, size) {
            fontFull.drawShapedRun(
              context.page,
              canvas,
              run,
              x: 50,
              y: 80,
              fontSize: 48,
            );
          },
        ),
      ),
    );
    await File('${scratchDir.path}/word_${word}_48pt_fullfont.pdf')
        .writeAsBytes(await docFull.save());
  }

  // 3. Generate the exact example document PDF
  final exampleDoc = pw.Document();
  exampleDoc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: KhmerText(
                  'ព្រះរាជាណាចក្រកម្ពុជា',
                  style: pw.TextStyle(
                    fontSize: 22,
                    color: PdfColors.indigo900,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Center(
                child: KhmerText(
                  'ជាតិ សាសនា ព្រះមហាក្សត្រ',
                  style: const pw.TextStyle(fontSize: 16),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.indigo300),
              pw.SizedBox(height: 12),
              KhmerText(
                'Invoice សួស្តី 123',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.blueGrey800,
                  font: pw.Font.helveticaBold(),
                ),
              ),
              pw.SizedBox(height: 6),
              KhmerText(
                'Price: \$10.50 កម្ពុជា | Total: \$21.00 រៀល',
                style: const pw.TextStyle(fontSize: 13),
              ),
              pw.SizedBox(height: 16),
              KhmerText(
                'ការពិពណ៌នា៖ ភាសាខ្មែរ គឺជាភាសាផ្លូវការរបស់ប្រទេសកម្ពុជា '
                'ដែលត្រូវបានប្រើប្រាស់ដោយប្រជាជនខ្មែររាប់លាននាក់។ '
                'កម្មវិធី Khmer PDF Shaper នេះជួយសម្រួលដល់ការបង្កើតឯកសារ PDF '
                'ឲ្យមានសោភ័ណភាពស្រស់ស្អាត ត្រឹមត្រូវតាមក្បួនខ្នាតអក្ខរាវិរុទ្ធខ្មែរ '
                'និងអាចស្វែងរក (Search) ឬចម្លង (Copy-Paste) អក្សរបានយ៉ាងរលូន។',
                style: const pw.TextStyle(fontSize: 12),
                lineHeightFactor: 1.6,
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                color: PdfColors.grey100,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    KhmerText(
                      'តម្រឹមឆ្វេង៖ សួស្តីកម្ពុជា',
                      style: const pw.TextStyle(fontSize: 11),
                      textAlign: pw.TextAlign.left,
                    ),
                    KhmerText(
                      'តម្រឹមកណ្តាល៖ ខ្ញុំស្រឡាញ់ភាសាខ្មែរ',
                      style: const pw.TextStyle(fontSize: 11),
                      textAlign: pw.TextAlign.center,
                    ),
                    KhmerText(
                      'តម្រឹមស្តាំ៖ អរគុណសន្តិភាព',
                      style: const pw.TextStyle(fontSize: 11),
                      textAlign: pw.TextAlign.right,
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Divider(),
              KhmerText(
                'Generated with pure Dart khmer_pdf_shaper',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        );
      },
    ),
  );
  await File('${scratchDir.path}/example_page.pdf')
      .writeAsBytes(await exampleDoc.save());

  print('All diagnostic PDFs generated successfully.');
}
