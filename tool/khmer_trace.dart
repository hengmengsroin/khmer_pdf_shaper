// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:tamil_pdf_shaper/khmer_pdf_shaper.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('{}');
    return;
  }

  final text = args[0];
  final run = KhmerPreprocessor.preprocess(text);

  final result = {
    'text': text,
    'input': run.inputChars
        .map((c) => {
              'cp': c.codePoint,
              'start': c.sourceStart,
              'end': c.sourceEnd,
              'cat': c.category.shortName,
            })
        .toList(),
    'normalized': run.normalizedChars
        .map((c) => {
              'cp': c.codePoint,
              'start': c.sourceStart,
              'end': c.sourceEnd,
              'cat': c.category.shortName,
              'synthetic': c.isSynthetic,
            })
        .toList(),
    'syllables': run.syllables
        .map((s) => {
              'type': s.type.name,
              'start': s.start,
              'end': s.end,
            })
        .toList(),
    'reordered': run.reorderedChars
        .map((c) => {
              'cp': c.codePoint,
              'start': c.sourceStart,
              'end': c.sourceEnd,
              'cluster': c.cluster,
              'cat': c.category.shortName,
              'pref': c.hasFeature(KhmerFeature.pref),
              'blwf': c.hasFeature(KhmerFeature.blwf),
              'abvf': c.hasFeature(KhmerFeature.abvf),
              'pstf': c.hasFeature(KhmerFeature.pstf),
              'cfar': c.hasFeature(KhmerFeature.cfar),
            })
        .toList(),
  };

  print(jsonEncode(result));
}
