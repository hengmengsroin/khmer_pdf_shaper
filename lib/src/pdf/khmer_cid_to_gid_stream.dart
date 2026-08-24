import 'dart:math' as math;
// ignore: implementation_imports
import 'package:pdf/src/pdf/obj/object_stream.dart';

/// PDF Object stream representing a `/CIDToGIDMap` mapping table.
///
/// Encodes a table of 2-byte big-endian integers mapping each CID (0..maxCid)
/// to its corresponding subset TrueType Glyph ID (GID).
class KhmerCidToGidStream extends PdfObjectStream {
  final Map<int, int> cidToSubsetGid;
  final int? maxCid;

  KhmerCidToGidStream(
    super.pdfDocument, {
    required this.cidToSubsetGid,
    this.maxCid,
  }) : super(isBinary: true);

  @override
  void prepare() {
    final effectiveMaxCid = maxCid ??
        (cidToSubsetGid.isEmpty
            ? 0
            : cidToSubsetGid.keys.fold<int>(0, math.max));

    for (int cid = 0; cid <= effectiveMaxCid; cid++) {
      final subsetGid = cidToSubsetGid[cid] ?? 0;
      buf.putByte((subsetGid >> 8) & 0xff);
      buf.putByte(subsetGid & 0xff);
    }
    super.prepare();
  }
}
