/// Types of layout tokens produced during run segmentation.
enum KhmerLayoutTokenType {
  /// Khmer script text run to be shaped by BattambangShaper.
  khmer,

  /// Latin, digits, or punctuation text run.
  latin,

  /// U+0020 SPACE (visible: true, breakOpportunity: true).
  space,

  /// U+00A0 NO-BREAK SPACE (visible: true, breakOpportunity: false).
  nbsp,

  /// U+200B ZERO WIDTH SPACE (visible: false, breakOpportunity: true).
  zwsp,
}

/// Token produced by run segmentation before shaping.
class KhmerLayoutToken {
  /// Token type determining shaping and breaking semantics.
  final KhmerLayoutTokenType type;

  /// Text content for this token.
  final String text;

  /// UTF-16 start offset in original paragraph.
  final int sourceStart;

  /// UTF-16 end offset (exclusive) in original paragraph.
  final int sourceEnd;

  const KhmerLayoutToken({
    required this.type,
    required this.text,
    required this.sourceStart,
    required this.sourceEnd,
  });

  /// Factory for Khmer text run.
  factory KhmerLayoutToken.khmer(String text, int start, int end) =>
      KhmerLayoutToken(
        type: KhmerLayoutTokenType.khmer,
        text: text,
        sourceStart: start,
        sourceEnd: end,
      );

  /// Factory for Latin/digits/punctuation text run.
  factory KhmerLayoutToken.latin(String text, int start, int end) =>
      KhmerLayoutToken(
        type: KhmerLayoutTokenType.latin,
        text: text,
        sourceStart: start,
        sourceEnd: end,
      );

  /// Factory for standard space (U+0020).
  factory KhmerLayoutToken.space(int start, int end) => KhmerLayoutToken(
        type: KhmerLayoutTokenType.space,
        text: ' ',
        sourceStart: start,
        sourceEnd: end,
      );

  /// Factory for non-breaking space (U+00A0).
  factory KhmerLayoutToken.nbsp(int start, int end) => KhmerLayoutToken(
        type: KhmerLayoutTokenType.nbsp,
        text: '\u00A0',
        sourceStart: start,
        sourceEnd: end,
      );

  /// Factory for zero-width space (U+200B).
  factory KhmerLayoutToken.zwsp(int start, int end) => KhmerLayoutToken(
        type: KhmerLayoutTokenType.zwsp,
        text: '\u200B',
        sourceStart: start,
        sourceEnd: end,
      );

  /// Whether this token is rendered visibly.
  bool get isVisible => type != KhmerLayoutTokenType.zwsp;

  /// Whether a line break is legally allowed after this token.
  bool get isBreakOpportunity =>
      type == KhmerLayoutTokenType.space || type == KhmerLayoutTokenType.zwsp;

  @override
  String toString() =>
      'KhmerLayoutToken($type, "$text", src: $sourceStart..$sourceEnd)';
}
