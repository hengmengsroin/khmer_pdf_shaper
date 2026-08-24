// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:tamil_pdf_shaper/src/khmer/khmer_features.dart';
import 'package:tamil_pdf_shaper/src/khmer/khmer_preprocessor.dart';

void main() {
  final file = File('test/fixtures/khmer_preprocessing_fixtures.json');
  final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final fixtures = jsonMap['fixtures'] as List<dynamic>;

  for (final f in fixtures) {
    final text = f['text'] as String;
    final run = KhmerPreprocessor.preprocess(text);
    f['syllables'] = run.syllables.map((s) => {'start': s.start, 'end': s.end, 'type': s.type.name}).toList();
    f['reordered'] = run.reorderedChars.map((c) => {
      'cp': c.codePoint,
      'start': c.sourceStart,
      'end': c.sourceEnd,
      'cluster': c.cluster,
      'cat': c.category.name,
      'mask': c.featureMask,
      'pref': c.hasFeature(KhmerFeature.pref),
      'blwf': c.hasFeature(KhmerFeature.blwf),
      'abvf': c.hasFeature(KhmerFeature.abvf),
      'pstf': c.hasFeature(KhmerFeature.pstf),
      'cfar': c.hasFeature(KhmerFeature.cfar),
      'synthetic': c.isSynthetic,
    }).toList();
  }

  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonMap));
  print('Updated preprocessing fixtures successfully.');
}
