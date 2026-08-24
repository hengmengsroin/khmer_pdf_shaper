import 'khmer_char.dart';
import 'khmer_normalizer.dart';
import 'khmer_reorder.dart';
import 'khmer_syllable.dart';
import 'khmer_syllable_parser.dart';

/// Preprocessed Khmer run holding intermediate representations and trace metadata.
class PreprocessedKhmerRun {
  /// Original raw input text.
  final String originalText;

  /// Decoded code points with initial UTF-16 source mapping.
  final List<KhmerChar> inputChars;

  /// Normalized code points after split-matra decomposition.
  final List<KhmerChar> normalizedChars;

  /// Discovered syllables matching HarfBuzz Ragel machine.
  final List<KhmerSyllable> syllables;

  /// Reordered characters with feature masks and merged shaping clusters.
  final List<KhmerChar> reorderedChars;

  PreprocessedKhmerRun({
    required this.originalText,
    required this.inputChars,
    required this.normalizedChars,
    required this.syllables,
    required this.reorderedChars,
  });

  /// Generates a human-readable trace representation of the preprocessing stages.
  String generateTrace() {
    final buffer = StringBuffer();

    buffer.writeln('INPUT');
    for (final c in inputChars) {
      final hex = 'U+${c.codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}';
      buffer.writeln('  $hex (src: ${c.sourceStart}..${c.sourceEnd}) [${c.category.shortName}]');
    }

    buffer.writeln('\nNORMALIZED');
    for (final c in normalizedChars) {
      final hex = 'U+${c.codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}';
      final synth = c.isSynthetic ? ' (synthetic from U+${c.originalCodePoints.map((x) => x.toRadixString(16).toUpperCase()).join(',')})' : '';
      buffer.writeln('  $hex (src: ${c.sourceStart}..${c.sourceEnd}) [${c.category.shortName}]$synth');
    }

    buffer.writeln('\nSYLLABLES');
    for (final s in syllables) {
      buffer.writeln('  ${s.start}..${s.end} ${s.type.name}');
    }

    buffer.writeln('\nREORDERED');
    for (final c in reorderedChars) {
      final hex = 'U+${c.codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}';
      final featStr = c.features.toString();
      buffer.writeln('  $hex (src: ${c.sourceStart}..${c.sourceEnd}, cluster: ${c.cluster}, feats: $featStr) [${c.category.shortName}]');
    }

    return buffer.toString();
  }

  @override
  String toString() => 'PreprocessedKhmerRun("${originalText.replaceAll('\n', '\\n')}", ${reorderedChars.length} chars, ${syllables.length} syllables)';
}

/// Main entry point for the Khmer script preprocessing pipeline.
class KhmerPreprocessor {
  KhmerPreprocessor._();

  /// Preprocesses Unicode [text] through normalization, categorization, syllable parsing,
  /// broken-cluster resolution, reordering, and feature-mask assignment.
  static PreprocessedKhmerRun preprocess(String text) {
    // 1. UTF-16 code point streaming and source provenance mapping
    final inputChars = KhmerCharStream.fromText(text);

    // 2. Normalization & split-matra decomposition
    final normalizedChars = KhmerNormalizer.normalize(inputChars);

    // 3. Syllable discovery (Ragel DFA)
    final syllables = KhmerSyllableParser.parse(normalizedChars);

    // 4. Broken-cluster handling, pre-GSUB reordering, and feature-mask assignment
    final reorderedChars = KhmerReorderer.reorder(normalizedChars, syllables);

    return PreprocessedKhmerRun(
      originalText: text,
      inputChars: inputChars,
      normalizedChars: normalizedChars,
      syllables: syllables,
      reorderedChars: reorderedChars,
    );
  }
}
