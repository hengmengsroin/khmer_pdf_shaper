import 'khmer_category.dart';
import 'khmer_char.dart';
import 'khmer_features.dart';
import 'khmer_syllable.dart';

/// Pre-GSUB reordering and feature-mask assignment engine for Khmer syllables.
class KhmerReorderer {
  KhmerReorderer._();

  /// Reorders normalized Khmer characters per syllable, assigns feature masks,
  /// inserts dotted circles (U+25CC) for broken clusters, and establishes
  /// monotone non-decreasing shaping cluster identifiers.
  static List<KhmerChar> reorder(
    List<KhmerChar> normalizedChars,
    List<KhmerSyllable> syllables,
  ) {
    if (normalizedChars.isEmpty) return const [];

    final List<KhmerChar> result = List.of(normalizedChars);

    // Process syllables from start to end, adjusting offsets if dotted circles are inserted.
    int offsetAdjustment = 0;

    for (final syllable in syllables) {
      int sylStart = syllable.start + offsetAdjustment;
      int sylEnd = syllable.end + offsetAdjustment;

      switch (syllable.type) {
        case KhmerSyllableType.brokenCluster:
          // If broken cluster is adjacent to a previous syllable/joiner without whitespace,
          // HarfBuzz merge_clusters merges it with the preceding cluster ID.
          int brokenClusterId = result[sylStart].cluster;
          if (sylStart > 0 && result[sylStart - 1].category != KhmerCategory.other) {
            brokenClusterId = result[sylStart - 1].cluster;
          }

          // Insert synthetic Dotted Circle U+25CC at the beginning of broken cluster
          final firstChar = result[sylStart];
          final dottedCircle = KhmerChar(
            codePoint: 0x25CC,
            sourceStart: firstChar.sourceStart,
            sourceEnd: firstChar.sourceEnd,
            cluster: brokenClusterId,
            category: KhmerCategory.dottedCircle,
            isSynthetic: true,
            originalCodePoints: const [],
          );
          result.insert(sylStart, dottedCircle);
          sylEnd++;
          offsetAdjustment++;

          for (int i = sylStart; i < sylEnd; i++) {
            result[i].cluster = brokenClusterId;
          }

          // Once dotted circle is inserted, broken cluster reorders as a consonant syllable
          _reorderConsonantSyllable(result, sylStart, sylEnd);
          break;

        case KhmerSyllableType.consonantSyllable:
          _reorderConsonantSyllable(result, sylStart, sylEnd);
          break;

        case KhmerSyllableType.nonKhmerCluster:
          // Non-Khmer clusters (spaces, latin, punctuation) undergo no reordering
          break;
      }
    }

    return result;
  }

  /// Reorders a consonant syllable matching HarfBuzz `reorder_consonant_syllable`.
  static void _reorderConsonantSyllable(
    List<KhmerChar> chars,
    int start,
    int end,
  ) {
    if (start >= end) return;

    // 1. Assign post-base masks (blwf, abvf, pstf) to all elements after base
    final int postBaseMask = KhmerFeature.blwf.mask |
        KhmerFeature.abvf.mask |
        KhmerFeature.pstf.mask;

    for (int i = start + 1; i < end; i++) {
      chars[i].featureMask |= postBaseMask;
    }

    // Determine base cluster identifier
    int minCluster = chars[start].cluster;
    for (int i = start; i < end; i++) {
      if (chars[i].cluster < minCluster) {
        minCluster = chars[i].cluster;
      }
    }

    // 2. Pre-GSUB Reordering loop
    int numCoengs = 0;
    for (int i = start + 1; i < end; i++) {
      if (chars[i].category == KhmerCategory.coeng &&
          numCoengs <= 2 &&
          (i + 1) < end) {
        numCoengs++;

        if (chars[i + 1].category == KhmerCategory.ra) {
          // COENG RO sequence
          chars[i].featureMask |= KhmerFeature.pref.mask;
          chars[i + 1].featureMask |= KhmerFeature.pref.mask;

          // Move [Coeng, Ro] to start of syllable
          final t0 = chars[i];
          final t1 = chars[i + 1];
          chars.removeRange(i, i + 2);
          chars.insert(start, t1);
          chars.insert(start, t0);

          // Mark subsequent items with CFAR (Conjunct Form After Ro)
          for (int j = i + 2; j < end; j++) {
            chars[j].featureMask |= KhmerFeature.cfar.mask;
          }

          numCoengs = 2; // Done with Coeng Ro
        }
      } else if (chars[i].category == KhmerCategory.vowelPre) {
        // Move Left Matra (VPre) to start of syllable
        final t = chars[i];
        chars.removeAt(i);
        chars.insert(start, t);
      }
    }

    // 3. Cluster association: all glyphs in syllable share the base cluster identifier
    for (int i = start; i < end; i++) {
      chars[i].cluster = minCluster;
    }
  }
}
