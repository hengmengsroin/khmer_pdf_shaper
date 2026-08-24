/// Script category definitions for Khmer shaper matching HarfBuzz Indic/Khmer model.
enum KhmerCategory {
  consonant(1, 'C', 'Consonant'),
  independentVowel(2, 'V', 'Independent Vowel'),
  coeng(4, 'H', 'Coeng / Subscript Stacker'),
  zwnj(5, 'ZWNJ', 'Zero-Width Non-Joiner'),
  zwj(6, 'ZWJ', 'Zero-Width Joiner'),
  placeholder(
      10, 'PLACEHOLDER', 'Placeholder / Dotted Circle substitute / Digits'),
  dottedCircle(11, 'DOTTEDCIRCLE', 'Dotted Circle (U+25CC)'),
  ra(15, 'Ra', 'Consonant Ra (U+179A)'),
  vowelAbove(20, 'VAbv', 'Vowel Above'),
  vowelBelow(21, 'VBlw', 'Vowel Below'),
  vowelPre(22, 'VPre', 'Pre-base Vowel (Left matra)'),
  vowelPost(23, 'VPst', 'Post-base Vowel (Right matra)'),
  robatic(25, 'Robatic', 'Robatic / Register Shifter / Robat'),
  xGroup(26, 'Xgroup', 'X-group Mark (Above / Killer / Tone)'),
  yGroup(27, 'Ygroup', 'Y-group Mark (Post mark / Visarga)'),
  other(0, 'X', 'Other / Non-Khmer');

  final int id;
  final String shortName;
  final String description;

  const KhmerCategory(this.id, this.shortName, this.description);
}

/// Authoritative character category classification derived directly from
/// HarfBuzz `hb_indic_get_categories()` and Unicode UCD data.
KhmerCategory getKhmerCategory(int codePoint) {
  // Fast dispatch for common ASCII / Latin / Controls
  if (codePoint < 0x00A0) {
    return KhmerCategory.other;
  }

  // Non-breaking space (treated as PLACEHOLDER in HarfBuzz Indic shaper)
  if (codePoint == 0x00A0) {
    return KhmerCategory.placeholder;
  }

  // Formatting & Punctuation
  if (codePoint == 0x200C) return KhmerCategory.zwnj;
  if (codePoint == 0x200D) return KhmerCategory.zwj;
  if (codePoint == 0x2015 || codePoint == 0x2022) {
    return KhmerCategory.placeholder;
  }
  if (codePoint == 0x25CC) return KhmerCategory.dottedCircle;
  if (codePoint >= 0x25FB && codePoint <= 0x25FE) {
    return KhmerCategory.placeholder;
  }

  // Khmer block (0x1780 .. 0x17FF)
  if (codePoint >= 0x1780 && codePoint <= 0x17FF) {
    // Consonants
    if (codePoint >= 0x1780 && codePoint <= 0x1799) {
      return KhmerCategory.consonant;
    }
    if (codePoint == 0x179A) return KhmerCategory.ra;
    if (codePoint >= 0x179B && codePoint <= 0x17A0) {
      return KhmerCategory.consonant;
    }
    if (codePoint == 0x17A1) {
      return KhmerCategory.placeholder; // LA cannot be subjoined
    }
    if (codePoint == 0x17A2) return KhmerCategory.consonant;

    // Independent Vowels
    if (codePoint >= 0x17A3 && codePoint <= 0x17B3) {
      return KhmerCategory.independentVowel;
    }

    // Inherent vowels / unassigned marks
    if (codePoint == 0x17B4 || codePoint == 0x17B5) return KhmerCategory.other;

    // Dependent Vowels
    if (codePoint == 0x17B6) return KhmerCategory.vowelPost;
    if (codePoint >= 0x17B7 && codePoint <= 0x17BA) {
      return KhmerCategory.vowelAbove;
    }
    if (codePoint >= 0x17BB && codePoint <= 0x17BD) {
      return KhmerCategory.vowelBelow;
    }

    // Split matras (classified according to UCD Indic positional before decomposition)
    if (codePoint == 0x17BE) return KhmerCategory.vowelAbove;
    if (codePoint >= 0x17BF && codePoint <= 0x17C0) {
      return KhmerCategory.vowelPost;
    }
    if (codePoint >= 0x17C1 && codePoint <= 0x17C3) {
      return KhmerCategory.vowelPre;
    }
    if (codePoint >= 0x17C4 && codePoint <= 0x17C5) {
      return KhmerCategory.vowelPost;
    }

    // Marks & Modifiers
    if (codePoint == 0x17C6) return KhmerCategory.xGroup; // Nikahit (Bindu)
    if (codePoint >= 0x17C7 && codePoint <= 0x17C8) {
      return KhmerCategory.yGroup; // Reahmuk, Yuukaleapintu
    }
    if (codePoint >= 0x17C9 && codePoint <= 0x17CA) {
      return KhmerCategory.robatic; // Muusikatoan, Triisap
    }
    if (codePoint == 0x17CB) return KhmerCategory.xGroup; // Bantoc
    if (codePoint == 0x17CC) return KhmerCategory.robatic; // Robat
    if (codePoint >= 0x17CD && codePoint <= 0x17D1) {
      return KhmerCategory
          .xGroup; // Toandakhiat, Kakabat, Ahsda, Samyok Sannya, Viriam
    }
    if (codePoint == 0x17D2) {
      return KhmerCategory.coeng; // Coeng (Stacker/Virama)
    }
    if (codePoint == 0x17D3) return KhmerCategory.yGroup; // Bathamasat

    // Punctuation & Signs
    if (codePoint >= 0x17D4 && codePoint <= 0x17D8) return KhmerCategory.other;
    if (codePoint == 0x17D9) return KhmerCategory.placeholder; // Phnaek Muan
    if (codePoint >= 0x17DA && codePoint <= 0x17DC) return KhmerCategory.other;
    if (codePoint == 0x17DD) return KhmerCategory.yGroup; // Atthacan
    if (codePoint >= 0x17DE && codePoint <= 0x17DF) return KhmerCategory.other;

    // Khmer Digits (0x17E0..0x17E9) -> PLACEHOLDER in HarfBuzz Indic shaper
    if (codePoint >= 0x17E0 && codePoint <= 0x17E9) {
      return KhmerCategory.placeholder;
    }

    // Divination signs & unassigned (0x17EA..0x17FF)
    return KhmerCategory.other;
  }

  // Khmer Symbols block (0x19E0..0x19FF) -> Other
  if (codePoint >= 0x19E0 && codePoint <= 0x19FF) {
    return KhmerCategory.other;
  }

  return KhmerCategory.other;
}
