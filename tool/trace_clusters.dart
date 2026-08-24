// ignore_for_file: avoid_print
import 'package:khmer_pdf_shaper/src/khmer/khmer_preprocessor.dart';

void main() {
  final cases = [
    'ក្ក',
    'ក្\u200dក',
    'ក្\u200cក',
    'ក\u200cេ',
    'ឥ\u200dក',
    'ក្\u200c្ក',
    'ក្ឡ',
    'កាិុ',
    'ក្្ក',
  ];

  for (final text in cases) {
    final run = KhmerPreprocessor.preprocess(text);
    print('=== $text ===');
    for (final s in run.syllables) {
      print('  syl: ${s.start}..${s.end} (${s.type.name})');
    }
    final charInfo = run.reorderedChars.map((c) => 'U+${c.codePoint.toRadixString(16).toUpperCase()}:${c.cluster}').join(' ');
    print('  reordered: $charInfo');
  }
}
