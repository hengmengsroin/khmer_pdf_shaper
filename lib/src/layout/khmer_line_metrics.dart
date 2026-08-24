/// Vertical font and line metrics calculator for Khmer text.
///
/// Battambang-Regular.ttf defines:
/// - `unitsPerEm`: 2048
/// - `ascent`: +2500 (from `hhea`/`OS/2` tables accommodating tall stacked superscripts e.g. U+17C6, U+17C7, U+17C8)
/// - `descent`: -1200 (from `hhea`/`OS/2` tables accommodating deep stacked subscripts e.g. Coeng Nyo, Coeng Ta)
/// - `lineGap`: 0
///
/// Natural line height is calculated directly as:
/// `(ascent - descent + lineGap) * fontSize / unitsPerEm = (2500 - (-1200) + 0) * fontSize / 2048 = 3700 * fontSize / 2048`
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

  /// Calculates the natural line height in PDF points for [fontSize] directly from font metrics.
  double calculateNaturalLineHeight(double fontSize) {
    final designHeight = fontAscent - fontDescent + fontLineGap;
    return designHeight * fontSize / unitsPerEm;
  }

  /// Calculates effective line height considering optional user [lineHeightFactor].
  double calculateLineHeight(double fontSize, [double? lineHeightFactor]) {
    final natural = calculateNaturalLineHeight(fontSize);
    if (lineHeightFactor != null && lineHeightFactor > 0) {
      return natural * lineHeightFactor;
    }
    return natural;
  }

  /// Calculates font ascent in PDF points.
  double calculateAscent(double fontSize) {
    return fontAscent * fontSize / unitsPerEm;
  }

  /// Calculates font descent magnitude in PDF points.
  double calculateDescent(double fontSize) {
    return fontDescent.abs() * fontSize / unitsPerEm;
  }

  /// Calculates vertical offset from the top of the line box to the text baseline in PDF points.
  double calculateBaselineOffset(double fontSize, [double? lineHeightFactor]) {
    final natural = calculateNaturalLineHeight(fontSize);
    final effective = calculateLineHeight(fontSize, lineHeightFactor);
    final ascentPts = calculateAscent(fontSize);
    return ascentPts + (effective - natural) / 2.0;
  }
}
