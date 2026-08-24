import 'package:pdf/pdf.dart';

/// Vertical font and line metrics calculator for Khmer and mixed-script text.
///
/// Battambang-Regular.ttf defines:
/// - `unitsPerEm`: 2048
/// - `ascent`: +2500 (from `hhea`/`OS/2` tables accommodating tall stacked superscripts e.g. U+17C6, U+17C7, U+17C8)
/// - `descent`: -1200 (from `hhea`/`OS/2` tables accommodating deep stacked subscripts e.g. Coeng Nyo, Coeng Ta)
/// - `lineGap`: 0
///
/// For mixed script lines, the line box metrics are derived as:
/// - `lineAscent = max(khmerAscent, latinAscent)`
/// - `lineDescent = max(khmerDescent, latinDescent)`
/// - `naturalLineHeight = lineAscent + lineDescent`
/// - `baselineOffset = lineAscent + (lineHeight - naturalLineHeight) / 2`
class KhmerLineMetrics {
  /// Font ascent in design units (+2500 for Battambang-Regular).
  final int fontAscent;

  /// Font descent in design units (-1200 for Battambang-Regular).
  final int fontDescent;

  /// Font line gap in design units (0 for Battambang-Regular).
  final int fontLineGap;

  /// Font units per Em (2048 for Battambang-Regular).
  final int unitsPerEm;

  const KhmerLineMetrics({
    this.fontAscent = 2500,
    this.fontDescent = -1200,
    this.fontLineGap = 0,
    this.unitsPerEm = 2048,
  });

  /// Calculates Khmer font ascent in PDF points.
  double calculateAscent(double fontSize) {
    return fontAscent * fontSize / unitsPerEm;
  }

  /// Calculates Khmer font descent magnitude in PDF points.
  double calculateDescent(double fontSize) {
    return fontDescent.abs() * fontSize / unitsPerEm;
  }

  /// Calculates Khmer natural line height in PDF points.
  double calculateNaturalLineHeight(double fontSize) {
    final designHeight = fontAscent - fontDescent + fontLineGap;
    return designHeight * fontSize / unitsPerEm;
  }

  /// Calculates effective line height considering user [lineHeightFactor].
  double calculateLineHeight(double fontSize, [double? lineHeightFactor]) {
    final natural = calculateNaturalLineHeight(fontSize);
    if (lineHeightFactor != null && lineHeightFactor > 0) {
      return natural * lineHeightFactor;
    }
    return natural;
  }

  /// Calculates vertical offset from line top to text baseline in PDF points.
  double calculateBaselineOffset(double fontSize, [double? lineHeightFactor]) {
    final natural = calculateNaturalLineHeight(fontSize);
    final effective = calculateLineHeight(fontSize, lineHeightFactor);
    final ascentPts = calculateAscent(fontSize);
    return ascentPts + (effective - natural) / 2.0;
  }

  /// Calculates combined line ascent for mixed fonts: max(khmerAscent, latinAscent).
  double calculateLineAscent(double fontSize, [PdfFont? latinFont]) {
    final khmerAsc = calculateAscent(fontSize);
    if (latinFont == null) return khmerAsc;
    final latinAsc = latinFont.ascent * fontSize;
    return khmerAsc > latinAsc ? khmerAsc : latinAsc;
  }

  /// Calculates combined line descent for mixed fonts: max(khmerDescent, latinDescent).
  double calculateLineDescent(double fontSize, [PdfFont? latinFont]) {
    final khmerDesc = calculateDescent(fontSize);
    if (latinFont == null) return khmerDesc;
    final latinDesc = latinFont.descent.abs() * fontSize;
    return khmerDesc > latinDesc ? khmerDesc : latinDesc;
  }

  /// Calculates natural line height accommodating both Khmer and Latin fonts.
  double calculateMixedNaturalLineHeight(double fontSize,
      [PdfFont? latinFont]) {
    final lineAsc = calculateLineAscent(fontSize, latinFont);
    final lineDesc = calculateLineDescent(fontSize, latinFont);
    return lineAsc + lineDesc;
  }

  /// Calculates effective line height for mixed fonts.
  double calculateMixedLineHeight(double fontSize,
      {PdfFont? latinFont, double? lineHeightFactor}) {
    final natural = calculateMixedNaturalLineHeight(fontSize, latinFont);
    if (lineHeightFactor != null && lineHeightFactor > 0) {
      return natural * lineHeightFactor;
    }
    return natural;
  }

  /// Calculates baseline offset for mixed fonts.
  double calculateMixedBaselineOffset(double fontSize,
      {PdfFont? latinFont, double? lineHeightFactor}) {
    final natural = calculateMixedNaturalLineHeight(fontSize, latinFont);
    final effective = calculateMixedLineHeight(fontSize,
        latinFont: latinFont, lineHeightFactor: lineHeightFactor);
    final lineAsc = calculateLineAscent(fontSize, latinFont);
    return lineAsc + (effective - natural) / 2.0;
  }
}
