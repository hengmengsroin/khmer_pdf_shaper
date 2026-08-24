import 'khmer_layout_token.dart';

/// Segments text into paragraphs, runs, and explicit layout control tokens
/// before font shaping.
class KhmerRunSegmenter {
  KhmerRunSegmenter._();

  /// Normalizes line endings (`\r\n` and `\r` to `\n`).
  static String normalizeNewlines(String text) {
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  /// Splits normalized [text] into logical paragraphs by newline (`\n`).
  static List<String> splitParagraphs(String text) {
    final normalized = normalizeNewlines(text);
    return normalized.split('\n');
  }

  /// Determines if a code point belongs to the Khmer Unicode script ranges
  /// or associated shaping joiners / dotted circle.
  static bool isKhmerCodePoint(int cp) {
    return (cp >= 0x1780 && cp <= 0x17FF) || // Khmer block
        (cp >= 0x19E0 && cp <= 0x19FF) || // Khmer Symbols block
        cp == 0x25CC || // Dotted circle
        cp == 0x200C || // ZWNJ
        cp == 0x200D; // ZWJ
  }

  /// Segments a single [paragraph] into a sequential list of [KhmerLayoutToken]s.
  ///
  /// [baseOffset] is the UTF-16 offset of this paragraph within the original document.
  static List<KhmerLayoutToken> segmentParagraph(
    String paragraph, [
    int baseOffset = 0,
  ]) {
    if (paragraph.isEmpty) {
      return <KhmerLayoutToken>[];
    }

    final tokens = <KhmerLayoutToken>[];
    final runes = paragraph.runes.toList();
    int runeIndex = 0;
    int utf16Offset = 0;

    while (runeIndex < runes.length) {
      final cp = runes[runeIndex];
      final charLen = cp > 0xFFFF ? 2 : 1;
      final startOffset = baseOffset + utf16Offset;

      if (cp == 0x0020) {
        // U+0020 SPACE
        tokens.add(KhmerLayoutToken.space(startOffset, startOffset + charLen));
        utf16Offset += charLen;
        runeIndex++;
      } else if (cp == 0x00A0) {
        // U+00A0 NBSP
        tokens.add(KhmerLayoutToken.nbsp(startOffset, startOffset + charLen));
        utf16Offset += charLen;
        runeIndex++;
      } else if (cp == 0x200B) {
        // U+200B ZWSP
        tokens.add(KhmerLayoutToken.zwsp(startOffset, startOffset + charLen));
        utf16Offset += charLen;
        runeIndex++;
      } else if (isKhmerCodePoint(cp)) {
        // Khmer text run
        final runBuffer = StringBuffer();
        final runStart = startOffset;

        while (runeIndex < runes.length) {
          final nextCp = runes[runeIndex];
          if (nextCp == 0x0020 ||
              nextCp == 0x00A0 ||
              nextCp == 0x200B ||
              !isKhmerCodePoint(nextCp)) {
            break;
          }
          runBuffer.writeCharCode(nextCp);
          final nextLen = nextCp > 0xFFFF ? 2 : 1;
          utf16Offset += nextLen;
          runeIndex++;
        }

        final runEnd = baseOffset + utf16Offset;
        tokens.add(KhmerLayoutToken.khmer(runBuffer.toString(), runStart, runEnd));
      } else {
        // Latin / Digits / Punctuation run
        final runBuffer = StringBuffer();
        final runStart = startOffset;

        while (runeIndex < runes.length) {
          final nextCp = runes[runeIndex];
          if (nextCp == 0x0020 ||
              nextCp == 0x00A0 ||
              nextCp == 0x200B ||
              isKhmerCodePoint(nextCp)) {
            break;
          }
          runBuffer.writeCharCode(nextCp);
          final nextLen = nextCp > 0xFFFF ? 2 : 1;
          utf16Offset += nextLen;
          runeIndex++;
        }

        final runEnd = baseOffset + utf16Offset;
        tokens.add(KhmerLayoutToken.latin(runBuffer.toString(), runStart, runEnd));
      }
    }

    return tokens;
  }
}
