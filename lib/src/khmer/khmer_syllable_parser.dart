import 'khmer_char.dart';
import 'khmer_syllable.dart';

/// Pure-Dart implementation of HarfBuzz Khmer syllable state machine (Ragel DFA).
/// Provides 100% state-machine parity with HarfBuzz .
class KhmerSyllableParser {
  KhmerSyllableParser._();

  static const List<int> _transKeys = [
  5, 26, 5, 26, 1, 15, 5, 26, 5, 26, 5, 26, 5, 26, 5, 26,
  5, 26, 5, 26, 5, 26, 5, 26, 5, 26, 1, 15, 5, 26, 5, 26,
  5, 26, 5, 26, 5, 26, 5, 26, 5, 26, 1, 27, 4, 27, 1, 15,
  4, 27, 4, 27, 27, 27, 4, 27, 4, 27, 4, 27, 4, 27, 4, 27,
  4, 27, 1, 15, 4, 27, 4, 27, 27, 27, 4, 27, 4, 27, 4, 27,
  4, 27, 4, 27, 5, 26, 0,
  ];

  static const List<int> _keySpans = [
  22, 22, 15, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 15, 22, 22,
  22, 22, 22, 22, 22, 27, 24, 15, 24, 24, 1, 24, 24, 24, 24, 24,
  24, 15, 24, 24, 1, 24, 24, 24, 24, 24, 22,
  ];

  static const List<int> _indexOffsets = [
  0, 23, 46, 62, 85, 108, 131, 154, 177, 200, 223, 246, 269, 292, 308, 331,
  354, 377, 400, 423, 446, 469, 497, 522, 538, 563, 588, 590, 615, 640, 665, 690,
  715, 740, 756, 781, 806, 808, 833, 858, 883, 908, 933,
  ];

  static const List<int> _indices = [
  1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2,
  0, 0, 0, 0, 3, 4, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 5, 5,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 1, 1,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0,
  0, 0, 0, 4, 0, 6, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 7, 7, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 8, 0, 9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 2, 0, 0, 0, 0, 0, 10, 0, 9, 9, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10,
  0, 11, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  2, 0, 0, 0, 0, 0, 12, 0, 11, 11, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 1,
  1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0,
  0, 0, 0, 13, 4, 0, 15, 15, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 16, 14, 14, 14, 14, 17, 18, 14, 15, 15, 19,
  19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19,
  19, 19, 18, 19, 20, 20, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 20, 14, 15, 15, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 16, 14, 14, 14, 14, 14, 18, 14, 21, 21, 14, 14, 14,
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  16, 14, 22, 22, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 14, 14, 23, 14, 24, 24, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 14, 14, 14, 16, 14, 14, 14, 14, 14, 25, 14,
  24, 24, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 25, 14, 26, 26, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 14, 16, 14, 14, 14, 14, 14, 27, 14, 26, 26,
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 27, 14, 29, 29, 28, 30, 31, 31, 28, 28, 28, 13, 13,
  28, 28, 28, 29, 28, 28, 28, 28, 16, 25, 27, 23, 28, 17, 18, 20,
  28, 33, 34, 34, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
  32, 2, 10, 12, 8, 32, 13, 4, 5, 32, 35, 35, 32, 32, 32, 32,
  32, 32, 32, 32, 32, 32, 32, 32, 35, 32, 33, 36, 36, 32, 32, 32,
  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 2, 10, 12, 8, 32, 3,
  4, 5, 32, 37, 38, 38, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
  32, 32, 32, 2, 10, 12, 8, 32, 32, 4, 5, 32, 5, 32, 37, 6,
  6, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
  32, 8, 32, 32, 2, 5, 32, 37, 7, 7, 32, 32, 32, 32, 32, 32,
  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 8, 5, 32,
  37, 39, 39, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
  2, 32, 32, 8, 32, 32, 10, 5, 32, 37, 40, 40, 32, 32, 32, 32,
  32, 32, 32, 32, 32, 32, 32, 32, 32, 2, 10, 32, 8, 32, 32, 12,
  5, 32, 33, 38, 38, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
  32, 32, 2, 10, 12, 8, 32, 32, 4, 5, 32, 33, 38, 38, 32, 32,
  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 2, 10, 12, 8, 32,
  3, 4, 5, 32, 42, 42, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41,
  41, 41, 42, 41, 30, 43, 43, 41, 41, 41, 41, 41, 41, 41, 41, 41,
  41, 41, 41, 41, 16, 25, 27, 23, 41, 17, 18, 20, 41, 44, 45, 45,
  41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 16, 25, 27,
  23, 41, 41, 18, 20, 41, 20, 41, 44, 21, 21, 41, 41, 41, 41, 41,
  41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 23, 41, 41, 16, 20,
  41, 44, 22, 22, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41,
  41, 41, 41, 41, 41, 41, 41, 23, 20, 41, 44, 46, 46, 41, 41, 41,
  41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 16, 41, 41, 23, 41, 41,
  25, 20, 41, 44, 47, 47, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41,
  41, 41, 41, 16, 25, 41, 23, 41, 41, 27, 20, 41, 30, 45, 45, 41,
  41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 16, 25, 27, 23,
  41, 41, 18, 20, 41, 15, 15, 48, 48, 48, 48, 48, 48, 48, 48, 48,
  48, 48, 48, 48, 16, 48, 48, 48, 48, 48, 18, 48, 0,
  ];

  static const List<int> _transTargs = [
  21, 1, 27, 31, 25, 26, 4, 5, 28, 7, 29, 9, 30, 32, 21, 12,
  37, 41, 35, 21, 36, 15, 16, 38, 18, 39, 20, 40, 21, 22, 33, 42,
  21, 23, 10, 24, 0, 2, 3, 6, 8, 21, 34, 11, 13, 14, 17, 19,
  21,
  ];

  static const List<int> _transActions = [
  1, 0, 2, 2, 2, 0, 0, 0, 2, 0, 2, 0, 2, 2, 3, 0,
  2, 4, 4, 5, 0, 0, 0, 2, 0, 2, 0, 2, 8, 2, 0, 9,
  10, 0, 0, 2, 0, 0, 0, 0, 0, 11, 4, 0, 0, 0, 0, 0,
  12,
  ];

  static const List<int> _toStateActions = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ];

  static const List<int> _fromStateActions = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ];

  static const List<int> _eofTrans = [
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 15, 20, 15, 15, 15,
  15, 15, 15, 15, 15, 0, 33, 33, 33, 33, 33, 33, 33, 33, 33, 33,
  33, 42, 42, 42, 42, 42, 42, 42, 42, 42, 49,
  ];

  static const int _startState = 21;

  /// Parses normalized [KhmerChar]s into a list of [KhmerSyllable]s.
  static List<KhmerSyllable> parse(List<KhmerChar> chars) {
    if (chars.isEmpty) return const [];

    final List<KhmerSyllable> syllables = [];
    int cs = _startState;
    int ts = 0;
    int te = 0;
    int act = 0;

    int p = 0;
    final int pe = chars.length;
    final int eof = pe;

    void foundSyllable(KhmerSyllableType type) {
      syllables.add(KhmerSyllable(type: type, start: ts, end: te));
    }

    while (true) {
      if (p == pe) {
        if (p == eof && _eofTrans[cs] > 0) {
          final int trans = _eofTrans[cs] - 1;
          cs = _transTargs[trans];
          final int action = _transActions[trans];
          switch (action) {
            case 2:
              te = p + 1;
              break;
            case 8:
              te = p + 1;
              foundSyllable(KhmerSyllableType.nonKhmerCluster);
              break;
            case 10:
              te = p;
              p--;
              foundSyllable(KhmerSyllableType.consonantSyllable);
              break;
            case 11:
              te = p;
              p--;
              foundSyllable(KhmerSyllableType.brokenCluster);
              break;
            case 12:
              te = p;
              p--;
              foundSyllable(KhmerSyllableType.nonKhmerCluster);
              break;
            case 1:
              p = te - 1;
              foundSyllable(KhmerSyllableType.consonantSyllable);
              break;
            case 3:
              p = te - 1;
              foundSyllable(KhmerSyllableType.brokenCluster);
              break;
            case 5:
              switch (act) {
                case 2:
                  p = te - 1;
                  foundSyllable(KhmerSyllableType.brokenCluster);
                  break;
                case 3:
                  p = te - 1;
                  foundSyllable(KhmerSyllableType.nonKhmerCluster);
                  break;
              }
              break;
            case 4:
              te = p + 1;
              act = 2;
              break;
            case 9:
              te = p + 1;
              act = 3;
              break;
          }
        }
        break;
      }

      if (_fromStateActions[cs] == 7) {
        ts = p;
      }

      final int keyIdx = cs << 1;
      final int k0 = _transKeys[keyIdx];
      final int k1 = _transKeys[keyIdx + 1];
      final int slen = _keySpans[cs];
      final int cat = chars[p].category.id;

      final int trans = _indices[_indexOffsets[cs] +
          (slen > 0 && k0 <= cat && cat <= k1 ? cat - k0 : slen)];

      cs = _transTargs[trans];
      final int action = _transActions[trans];

      if (action != 0) {
        switch (action) {
          case 2:
            te = p + 1;
            break;
          case 8:
            te = p + 1;
            foundSyllable(KhmerSyllableType.nonKhmerCluster);
            break;
          case 10:
            te = p;
            p--;
            foundSyllable(KhmerSyllableType.consonantSyllable);
            break;
          case 11:
            te = p;
            p--;
            foundSyllable(KhmerSyllableType.brokenCluster);
            break;
          case 12:
            te = p;
            p--;
            foundSyllable(KhmerSyllableType.nonKhmerCluster);
            break;
          case 1:
            p = te - 1;
            foundSyllable(KhmerSyllableType.consonantSyllable);
            break;
          case 3:
            p = te - 1;
            foundSyllable(KhmerSyllableType.brokenCluster);
            break;
          case 5:
            switch (act) {
              case 2:
                p = te - 1;
                foundSyllable(KhmerSyllableType.brokenCluster);
                break;
              case 3:
                p = te - 1;
                foundSyllable(KhmerSyllableType.nonKhmerCluster);
                break;
            }
            break;
          case 4:
            te = p + 1;
            act = 2;
            break;
          case 9:
            te = p + 1;
            act = 3;
            break;
        }
      }

      if (_toStateActions[cs] == 6) {
        ts = 0;
      }

      p++;
    }

    return syllables;
  }
}
