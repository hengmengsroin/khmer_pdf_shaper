// ignore: implementation_imports
import 'package:pdf/src/pdf/obj/object_stream.dart';

/// PDF Object stream representing an Adobe `/ToUnicode` CMap.
///
/// Supports multi-character Unicode cluster strings (e.g. `<0001> <178017D21780>`)
/// and explicit empty mappings for secondary visual glyphs (`<0002> <>`),
/// respecting the 100-entry limit per `beginbfchar / endbfchar` block as specified
/// in Adobe CMap specifications.
class KhmerToUnicodeCmap extends PdfObjectStream {
  final Map<int, String> cidToUnicode;

  KhmerToUnicodeCmap(
    super.pdfDocument, {
    required this.cidToUnicode,
  });

  @override
  void prepare() {
    buf.putString(
      '/CIDInit /ProcSet findresource begin\n'
      '12 dict begin\n'
      'begincmap\n'
      '/CIDSystemInfo <<\n'
      '  /Registry (Adobe)\n'
      '  /Ordering (UCS)\n'
      '  /Supplement 0\n'
      '>> def\n'
      '/CMapName /Adobe-Identity-UCS def\n'
      '/CMapType 2 def\n'
      '1 begincodespacerange\n'
      '<0000> <FFFF>\n'
      'endcodespacerange\n',
    );

    final entries = <({String cidHex, String unicodeHex})>[];
    final sortedCids = cidToUnicode.keys.toList()..sort();

    for (final cid in sortedCids) {
      if (cid == 0) continue; // Skip CID 0 (.notdef)
      final unicodeStr = cidToUnicode[cid] ?? '';

      final cidHex = cid.toRadixString(16).toUpperCase().padLeft(4, '0');
      final unicodeHex = unicodeStr.codeUnits
          .map((u) => u.toRadixString(16).toUpperCase().padLeft(4, '0'))
          .join();
      entries.add((cidHex: cidHex, unicodeHex: unicodeHex));
    }

    // Split entries into blocks of at most 100 entries per PDF/CMap specification
    const chunkSize = 100;
    for (int i = 0; i < entries.length; i += chunkSize) {
      final end = (i + chunkSize < entries.length) ? i + chunkSize : entries.length;
      final chunk = entries.sublist(i, end);

      buf.putString('${chunk.length} beginbfchar\n');
      for (final entry in chunk) {
        buf.putString('<${entry.cidHex}> <${entry.unicodeHex}>\n');
      }
      buf.putString('endbfchar\n');
    }

    buf.putString(
      'endcmap\n'
      'CMapName currentdict /CMap defineresource pop\n'
      'end\n'
      'end\n',
    );

    super.prepare();
  }
}
