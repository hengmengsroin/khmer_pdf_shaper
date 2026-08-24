import 'dart:typed_data';
import 'package:pdf/pdf.dart';
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

import '../shaper/shaped_run.dart';
import 'khmer_cid_registry.dart';
import 'khmer_cid_to_gid_stream.dart';
import 'khmer_tounicode_cmap.dart';
import 'truetype_gid_subsetter.dart';

/// OpenType/TrueType Type0 CIDFont implementation for rendered Khmer text in `package:pdf`.
///
/// Manages:
/// - Accumulating used glyphs across multiple runs and pages
/// - Subsetting the TrueType font binary on `PdfDocument.save()`
/// - Allocating CIDs with semantic cluster ownership
/// - Emitting two-byte big-endian `/CIDToGIDMap` binary streams
/// - Emitting multi-character Adobe `/ToUnicode` CMaps
/// - Decoupling document-level nominal font widths (`/W`) from occurrence-level shaped advances
class KhmerPdfFont extends PdfFont {
  final TtfParser font;
  final TrueTypeGidSubsetter _subsetter;
  final KhmerCidRegistry _registry = KhmerCidRegistry();
  final Set<int> _usedOriginalGids = <int>{0};

  late final PdfObjectStream _file;
  late final PdfFontDescriptor _descriptor;
  late final PdfObject<PdfArray> _widthsObject;
  late final KhmerCidToGidStream _cidToGidStream;
  late final KhmerToUnicodeCmap _toUnicodeCmap;

  final Map<int, int> _cidToSubsetGid = <int, int>{};
  final Map<int, String> _cidToUnicode = <int, String>{};

  /// Constructs a [KhmerPdfFont] for [pdfDocument] using TrueType [fontBytes].
  KhmerPdfFont(super.pdfDocument, ByteData fontBytes)
      : font = TtfParser(fontBytes),
        _subsetter = TrueTypeGidSubsetter(TtfParser(fontBytes)),
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
  }

  @override
  String get fontName => font.fontName;

  @override
  double get ascent => font.ascent.toDouble() / font.unitsPerEm;

  @override
  double get descent => font.descent.toDouble() / font.unitsPerEm;

  @override
  int get unitsPerEm => font.unitsPerEm;

  /// The CID registry managing semantic character identifier mappings.
  KhmerCidRegistry get registry => _registry;

  /// Returns nominal advance width in font design units from the font's `hmtx` table.
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
  PdfFontMetrics glyphMetrics(int charCode) {
    return font.glyphInfoMap[charCode] ?? PdfFontMetrics.zero;
  }

  @override
  bool isRuneSupported(int charCode) => true;

  /// Draws a [ShapedRun] onto [page] / [graphics] at baseline position ([x], [y]) with [fontSize].
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

    // 1. Semantic cluster analysis & CID allocation
    final glyphCodes = <PdfGlyphCode>[];
    for (final cluster in run.clusters) {
      final clusterText =
          run.originalText.substring(cluster.sourceStart, cluster.sourceEnd);
      for (int i = 0; i < cluster.glyphs.length; i++) {
        final g = cluster.glyphs[i];
        _usedOriginalGids.add(g.glyphId);
        final code = _registry.allocate(
          originalGlyphId: g.glyphId,
          subsetGlyphId: 0, // Resolved at prepare() time
          unicodeText: (i == 0) ? clusterText : '',
        );
        glyphCodes.add(code);
      }
    }

    // 2. Register font with graphics context / page resources
    graphics.setFont(this, fontSize);

    // 3. Emit positioned PDF text operators
    stream.putString('BT\n');
    stream.putString('$name $fontSize Tf\n');
    stream.putString('$x $y Td\n');
    stream.putString('[');

    for (int i = 0; i < run.glyphs.length; i++) {
      final g = run.glyphs[i];
      final code = glyphCodes[i];
      final cidHex = code.cid.toRadixString(16).toUpperCase().padLeft(4, '0');
      stream.putString('<$cidHex>');

      final nomDesign = nominalDesignWidth(g.glyphId);
      final shapedDesign = g.xAdvance.round();
      final diff = nomDesign - shapedDesign;
      if (diff != 0) {
        // Kerning / advance adjustment in 1/1000 text units:
        // adjustment = (nominal - shaped) * 1000 / unitsPerEm
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

    // 1. Subset TrueType font containing all accumulated GIDs + compound dependencies
    final subsetResult = _subsetter.subsetGlyphs(_usedOriginalGids);
    _file.buf.putBytes(subsetResult.fontBytes);
    _file.params['/Length1'] = PdfNum(subsetResult.fontBytes.length);

    // 2. Build CID to subset GID map and CID to Unicode map
    _cidToSubsetGid.clear();
    _cidToUnicode.clear();

    for (final entry in _registry.entries.values) {
      final subsetGid =
          subsetResult.originalToSubset[entry.originalGlyphId] ?? 0;
      _cidToSubsetGid[entry.cid] = subsetGid;
      _cidToUnicode[entry.cid] = entry.unicodeText;
    }

    // 3. Populate /W table (nominal font widths per CID scaled to 1000 units)
    _widthsObject.params.values.clear();
    for (int cid = 0; cid <= _registry.maxCid; cid++) {
      final origGid = _registry.getByCid(cid)?.originalGlyphId ?? 0;
      final nomWidth =
          (nominalDesignWidth(origGid) * 1000.0 / unitsPerEm).round();
      _widthsObject.params.add(PdfNum(nomWidth));
    }

    // 4. Build Descendant CIDFontType2 dictionary
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

    // 5. Populate Type0 Font dictionary
    params['/BaseFont'] = PdfName('/$fontName');
    params['/Encoding'] = const PdfName('/Identity-H');
    params['/DescendantFonts'] = PdfArray([descendantFont]);
    params['/ToUnicode'] = _toUnicodeCmap.ref();
  }
}
