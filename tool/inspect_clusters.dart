// ignore_for_file: avoid_print
import 'dart:io';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_cid_registry.dart';

void main() {
  final fontBytes = File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
  final shaper = BattambangShaper.fromBytes(fontBytes);
  final words = ['ក្រ', 'គ្រែ', 'ខ្ញុំ', 'សួស្តី'];

  for (final word in words) {
    print('=== Word: $word ===');
    final run = shaper.shapeText(word);
    final registry = KhmerCidRegistry();

    for (int ci = 0; ci < run.clusters.length; ci++) {
      final cluster = run.clusters[ci];
      final clusterText = run.originalText.substring(cluster.sourceStart, cluster.sourceEnd);
      print('Cluster $ci:');
      print('  semantic_cluster:');
      print('    source_range: ${cluster.sourceStart}..${cluster.sourceEnd}');
      print('    original_text: "$clusterText"');

      for (int gi = 0; gi < cluster.glyphs.length; gi++) {
        final g = cluster.glyphs[gi];
        final isPrimary = (gi == 0);
        final unicodeText = isPrimary ? clusterText : '';
        final code = registry.allocate(
          originalGlyphId: g.glyphId,
          subsetGlyphId: gi + 1,
          unicodeText: unicodeText,
        );

        print('  visual_glyph $gi:');
        print('    gid: ${g.glyphId}');
        print('    own_source_range: ${g.sourceStart}..${g.sourceEnd}');
        print('    cluster: ${g.cluster}');
        print('    is_primary: $isPrimary');
        print('    allocated_cid: ${code.cid}');
        print('    tounicode_mapping: "$unicodeText"');
      }
    }
    print('');
  }
}
