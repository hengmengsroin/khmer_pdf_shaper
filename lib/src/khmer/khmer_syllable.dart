/// Types of syllables identified by the Khmer syllable state machine.
enum KhmerSyllableType {
  /// A valid Khmer consonant syllable starting with a consonant or independent vowel.
  consonantSyllable('consonant_syllable'),

  /// A broken or malformed cluster (e.g. standalone mark, isolated subscript) requiring a dotted circle.
  brokenCluster('broken_cluster'),

  /// Non-Khmer text, symbols, spaces, digits, or unrelated Unicode runs.
  nonKhmerCluster('non_khmer_cluster');

  final String name;
  const KhmerSyllableType(this.name);

  @override
  String toString() => name;
}

/// A parsed syllable segment bounded by indexes in the normalized character stream.
class KhmerSyllable {
  final KhmerSyllableType type;

  /// Start index in the normalized character list (inclusive).
  final int start;

  /// End index in the normalized character list (exclusive).
  final int end;

  const KhmerSyllable({
    required this.type,
    required this.start,
    required this.end,
  });

  int get length => end - start;

  @override
  String toString() => 'KhmerSyllable($start..$end, $type)';
}
