import 'dart:math' as math;
import 'dart:typed_data';
// ignore: implementation_imports
import 'package:pdf/src/pdf/font/ttf_parser.dart';

/// Result of TrueType GID subsetting containing the new font bytes and bidirectional GID mappings.
class TrueTypeGidSubsetResult {
  /// The binary bytes of the valid subset TrueType font.
  final Uint8List fontBytes;

  /// Mapping from original font GID to new subset GID.
  final Map<int, int> originalToSubset;

  /// Mapping from new subset GID to original font GID.
  final Map<int, int> subsetToOriginal;

  const TrueTypeGidSubsetResult({
    required this.fontBytes,
    required this.originalToSubset,
    required this.subsetToOriginal,
  });
}

/// Standalone TrueType font subsetter that extracts arbitrary OpenType GIDs
/// (including unmapped GSUB ligatures, subscripts, and marks) and resolves
/// composite glyph dependencies.
class TrueTypeGidSubsetter {
  final TtfParser ttf;

  TrueTypeGidSubsetter(this.ttf);

  int _calcTableChecksum(ByteData table) {
    assert(table.lengthInBytes % 4 == 0);
    var sum = 0;
    for (var i = 0; i < table.lengthInBytes - 3; i += 4) {
      sum = (sum + table.getUint32(i)) & 0xffffffff;
    }
    return sum;
  }

  void _updateCompoundGlyph(TtfGlyphInfo glyph, Map<int, int?> compoundMap) {
    const arg1And2AreWords = 1;
    const weHaveAScale = 8;
    const moreComponents = 32;
    const weHaveAnXAndYScale = 64;
    const weHaveATwoByTwo = 128;

    var offset = 10;
    final bytes = glyph.data.buffer.asByteData(
      glyph.data.offsetInBytes,
      glyph.data.lengthInBytes,
    );
    var flags = moreComponents;

    while (flags & moreComponents != 0) {
      if (offset + 4 > bytes.lengthInBytes) {
        break;
      }
      flags = bytes.getUint16(offset);
      final glyphIndex = bytes.getUint16(offset + 2);
      final newIndex = compoundMap[glyphIndex];
      if (newIndex != null) {
        bytes.setUint16(offset + 2, newIndex);
      }
      offset += (flags & arg1And2AreWords != 0) ? 8 : 6;
      if (flags & weHaveAScale != 0) {
        offset += 2;
      } else if (flags & weHaveAnXAndYScale != 0) {
        offset += 4;
      } else if (flags & weHaveATwoByTwo != 0) {
        offset += 8;
      }
    }
  }

  int _wordAlign(int offset, [int align = 4]) {
    return offset + ((align - (offset % align)) % align);
  }

  /// Generates a valid TrueType font binary containing only [glyphIds] and their compound dependencies.
  /// Always includes glyph 0 (.notdef).
  TrueTypeGidSubsetResult subsetGlyphs(Iterable<int> glyphIds) {
    final tables = <String, Uint8List>{};
    final tablesLength = <String, int>{};

    final requestedGids = <int>{0, ...glyphIds};
    final glyphsMap = <int, TtfGlyphInfo>{};
    final compounds = <int, int>{};

    void addGlyph(int gid) {
      if (glyphsMap.containsKey(gid)) return;
      if (gid >= ttf.glyphOffsets.length) return;
      final glyph = ttf.readGlyph(gid).copy();
      glyphsMap[gid] = glyph;
      for (final compGid in glyph.compounds) {
        compounds[compGid] = -1;
        addGlyph(compGid);
      }
    }

    for (final gid in requestedGids) {
      addGlyph(gid);
    }

    // Stable deterministic ordering: glyph 0 first, then sorted by original GID
    final sortedOriginalGids = glyphsMap.keys.toList()..sort();
    final glyphsInfo = <TtfGlyphInfo>[];
    final originalToSubset = <int, int>{};
    final subsetToOriginal = <int, int>{};

    for (int subsetGid = 0; subsetGid < sortedOriginalGids.length; subsetGid++) {
      final origGid = sortedOriginalGids[subsetGid];
      glyphsInfo.add(glyphsMap[origGid]!);
      originalToSubset[origGid] = subsetGid;
      subsetToOriginal[subsetGid] = origGid;
    }

    // Remap compound components to new subset GIDs
    for (final compGid in compounds.keys.toList()) {
      compounds[compGid] = originalToSubset[compGid] ?? 0;
    }

    // Update compound indices inside glyph bytes
    for (final glyph in glyphsInfo) {
      if (glyph.compounds.isNotEmpty) {
        _updateCompoundGlyph(glyph, compounds);
      }
    }

    // 1. glyf table
    var glyphsTableLength = 0;
    for (final glyph in glyphsInfo) {
      glyphsTableLength = _wordAlign(glyphsTableLength + glyph.data.lengthInBytes);
    }
    var offset = 0;
    final glyphsTable = Uint8List(_wordAlign(glyphsTableLength));
    tables[TtfParser.glyf_table] = glyphsTable;
    tablesLength[TtfParser.glyf_table] = glyphsTableLength;

    // 2. loca table
    final numGlyphs = glyphsInfo.length;
    if (ttf.indexToLocFormat == 0) {
      tables[TtfParser.loca_table] = Uint8List(_wordAlign((numGlyphs + 1) * 2));
      tablesLength[TtfParser.loca_table] = (numGlyphs + 1) * 2;
    } else {
      tables[TtfParser.loca_table] = Uint8List(_wordAlign((numGlyphs + 1) * 4));
      tablesLength[TtfParser.loca_table] = (numGlyphs + 1) * 4;
    }

    final loca = tables[TtfParser.loca_table]!.buffer.asByteData();
    var index = 0;
    for (final glyph in glyphsInfo) {
      if (ttf.indexToLocFormat == 0) {
        loca.setUint16(index, offset ~/ 2);
        index += 2;
      } else {
        loca.setUint32(index, offset);
        index += 4;
      }
      glyphsTable.setAll(offset, glyph.data);
      offset = _wordAlign(offset + glyph.data.lengthInBytes);
    }
    if (ttf.indexToLocFormat == 0) {
      loca.setUint16(index, offset ~/ 2);
    } else {
      loca.setUint32(index, offset);
    }

    // 3. Copy head, maxp, hhea, os_2 tables from original font
    for (final tn in {
      TtfParser.head_table,
      TtfParser.maxp_table,
      TtfParser.hhea_table,
      TtfParser.os_2_table,
    }) {
      final start = ttf.tableOffsets[tn];
      if (start == null) continue;
      final len = ttf.tableSize[tn]!;
      final data = Uint8List.fromList(ttf.bytes.buffer.asUint8List(start, _wordAlign(len)));
      tables[tn] = data;
      tablesLength[tn] = len;
    }

    // Fix head checkSumAdjustment, maxp numGlyphs, hhea numberOfHMetrics
    tables[TtfParser.head_table]!.buffer.asByteData().setUint32(8, 0);
    tables[TtfParser.maxp_table]!.buffer.asByteData().setUint16(4, numGlyphs);
    tables[TtfParser.hhea_table]!.buffer.asByteData().setUint16(34, numGlyphs);

    // 4. post table (version 3.0)
    {
      final start = ttf.tableOffsets[TtfParser.post_table]!;
      const len = 32;
      final data = Uint8List.fromList(ttf.bytes.buffer.asUint8List(start, _wordAlign(len)));
      data.buffer.asByteData().setUint32(0, 0x00030000);
      tables[TtfParser.post_table] = data;
      tablesLength[TtfParser.post_table] = len;
    }

    // 5. hmtx table (nominal font metrics per subset GID)
    {
      final len = 4 * numGlyphs;
      final hmtx = Uint8List(_wordAlign(len));
      final hmtxOffset = ttf.tableOffsets[TtfParser.hmtx_table]!;
      final hmtxData = hmtx.buffer.asByteData();
      final origHmtx = ttf.bytes.buffer.asByteData(hmtxOffset, ttf.tableSize[TtfParser.hmtx_table]!);
      final numLongMetrics = ttf.numOfLongHorMetrics;

      for (int subsetGid = 0; subsetGid < numGlyphs; subsetGid++) {
        final origGid = subsetToOriginal[subsetGid]!;
        int advWidth = 0;
        int lsb = 0;
        if (origGid < numLongMetrics) {
          advWidth = origHmtx.getUint16(origGid * 4);
          lsb = origHmtx.getInt16(origGid * 4 + 2);
        } else {
          advWidth = origHmtx.getUint16((numLongMetrics - 1) * 4);
          final lsbOffset = numLongMetrics * 4 + (origGid - numLongMetrics) * 2;
          if (lsbOffset + 2 <= origHmtx.lengthInBytes) {
            lsb = origHmtx.getInt16(lsbOffset);
          }
        }
        hmtxData.setUint16(subsetGid * 4, advWidth);
        hmtxData.setInt16(subsetGid * 4 + 2, lsb);
      }
      tables[TtfParser.hmtx_table] = hmtx;
      tablesLength[TtfParser.hmtx_table] = len;
    }

    // 6. CMAP table (format 12)
    {
      const len = 40;
      final cmap = Uint8List(_wordAlign(len));
      final cmapData = cmap.buffer.asByteData();
      cmapData.setUint16(0, 0); // Table version
      cmapData.setUint16(2, 1); // 1 encoding table
      cmapData.setUint16(4, 3); // Windows platform
      cmapData.setUint16(6, 10); // UCS-4
      cmapData.setUint32(8, 12); // Offset
      cmapData.setUint16(12, 12); // Format 12
      cmapData.setUint32(16, 28); // Length
      cmapData.setUint32(20, 1); // Language
      cmapData.setUint32(24, 1); // numGroups
      cmapData.setUint32(28, 32); // startCharCode
      cmapData.setUint32(32, numGlyphs + 31); // endCharCode
      cmapData.setUint32(36, 0); // startGlyphID
      tables[TtfParser.cmap_table] = cmap;
      tablesLength[TtfParser.cmap_table] = len;
    }

    // 7. name table
    {
      const len = 18;
      final nameBuf = Uint8List(_wordAlign(len));
      final nameData = nameBuf.buffer.asByteData();
      nameData.setUint16(0, 0);
      nameData.setUint16(2, 0);
      nameData.setUint16(4, 6);
      tables[TtfParser.name_table] = nameBuf;
      tablesLength[TtfParser.name_table] = len;
    }

    // 8. Build final sfnt font file
    final tableCount = tables.length;
    var totalSize = 12 + 16 * tableCount;
    for (final data in tables.values) {
      totalSize += data.lengthInBytes;
    }

    final out = Uint8List(totalSize);
    final outData = out.buffer.asByteData();

    // sfnt header
    outData.setUint32(0, 0x00010000); // TrueType outline
    outData.setUint16(4, tableCount);
    final entrySelector = (math.log(tableCount) / math.ln2).floor();
    final searchRange = (1 << entrySelector) * 16;
    final rangeShift = tableCount * 16 - searchRange;
    outData.setUint16(6, searchRange);
    outData.setUint16(8, entrySelector);
    outData.setUint16(10, rangeShift);

    // Write table directory
    var tableOffset = 12 + 16 * tableCount;
    var dirIndex = 12;

    final sortedTags = tables.keys.toList()..sort();
    for (final tag in sortedTags) {
      final tableBytes = tables[tag]!;
      final actualLen = tablesLength[tag]!;
      final tagChars = tag.codeUnits;

      for (int i = 0; i < 4; i++) {
        outData.setUint8(dirIndex + i, tagChars[i]);
      }
      outData.setUint32(dirIndex + 4, _calcTableChecksum(tableBytes.buffer.asByteData()));
      outData.setUint32(dirIndex + 8, tableOffset);
      outData.setUint32(dirIndex + 12, actualLen);
      dirIndex += 16;

      out.setAll(tableOffset, tableBytes);
      tableOffset += tableBytes.lengthInBytes;
    }

    // Compute checkSumAdjustment in head table
    final headOffset = outData.getUint32(
      12 + 16 * sortedTags.indexOf(TtfParser.head_table) + 8,
    );
    final fontChecksum = _calcTableChecksum(outData);
    final checkSumAdjustment = (0xb1b0afba - fontChecksum) & 0xffffffff;
    outData.setUint32(headOffset + 8, checkSumAdjustment);

    return TrueTypeGidSubsetResult(
      fontBytes: out,
      originalToSubset: originalToSubset,
      subsetToOriginal: subsetToOriginal,
    );
  }
}
