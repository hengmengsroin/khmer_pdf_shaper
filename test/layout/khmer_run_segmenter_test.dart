import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/layout/khmer_layout_token.dart';
import 'package:khmer_pdf_shaper/src/layout/khmer_run_segmenter.dart';

void main() {
  group('Part 2: Run Segmentation Tests', () {
    test('Newline normalization handles CR, LF, and CRLF', () {
      expect(KhmerRunSegmenter.normalizeNewlines('A\r\nB\rC\nD'), 'A\nB\nC\nD');
      expect(KhmerRunSegmenter.splitParagraphs('សួស្តី\nកម្ពុជា'),
          ['សួស្តី', 'កម្ពុជា']);
      expect(KhmerRunSegmenter.splitParagraphs('សួស្តី\r\nកម្ពុជា'),
          ['សួស្តី', 'កម្ពុជា']);
      expect(KhmerRunSegmenter.splitParagraphs('សួស្តី\n\nកម្ពុជា'),
          ['សួស្តី', '', 'កម្ពុជា']);
    });

    test('Segments "Invoice សួស្តី 123" into Latin, Space, Khmer, Space, Latin',
        () {
      const text = 'Invoice សួស្តី 123';
      final tokens = KhmerRunSegmenter.segmentParagraph(text);

      expect(tokens.length, 5);
      expect(tokens[0].type, KhmerLayoutTokenType.latin);
      expect(tokens[0].text, 'Invoice');
      expect(tokens[0].sourceStart, 0);
      expect(tokens[0].sourceEnd, 7);

      expect(tokens[1].type, KhmerLayoutTokenType.space);
      expect(tokens[1].isBreakOpportunity, isTrue);
      expect(tokens[1].isVisible, isTrue);

      expect(tokens[2].type, KhmerLayoutTokenType.khmer);
      expect(tokens[2].text, 'សួស្តី');
      expect(tokens[2].sourceStart, 8);
      expect(tokens[2].sourceEnd, 14);

      expect(tokens[3].type, KhmerLayoutTokenType.space);
      expect(tokens[3].isBreakOpportunity, isTrue);

      expect(tokens[4].type, KhmerLayoutTokenType.latin);
      expect(tokens[4].text, '123');
      expect(tokens[4].sourceStart, 15);
      expect(tokens[4].sourceEnd, 18);
    });

    test('Segments "Price: 10\$ កម្ពុជា" correctly', () {
      const text = 'Price: 10\$ កម្ពុជា';
      final tokens = KhmerRunSegmenter.segmentParagraph(text);

      expect(tokens.length, 5);
      expect(tokens[0].type, KhmerLayoutTokenType.latin);
      expect(tokens[0].text, 'Price:');
      expect(tokens[1].type, KhmerLayoutTokenType.space);
      expect(tokens[2].type, KhmerLayoutTokenType.latin);
      expect(tokens[2].text, '10\$');
      expect(tokens[3].type, KhmerLayoutTokenType.space);
      expect(tokens[4].type, KhmerLayoutTokenType.khmer);
      expect(tokens[4].text, 'កម្ពុជា');
    });

    test('Segments "ABCកម្ពុជា123" without spaces into contiguous runs', () {
      const text = 'ABCកម្ពុជា123';
      final tokens = KhmerRunSegmenter.segmentParagraph(text);

      expect(tokens.length, 3);
      expect(tokens[0].type, KhmerLayoutTokenType.latin);
      expect(tokens[0].text, 'ABC');
      expect(tokens[1].type, KhmerLayoutTokenType.khmer);
      expect(tokens[1].text, 'កម្ពុជា');
      expect(tokens[2].type, KhmerLayoutTokenType.latin);
      expect(tokens[2].text, '123');
    });

    test('Differentiates SPACE, NBSP, and ZWSP semantics explicitly', () {
      // SPACE
      final spaceTokens = KhmerRunSegmenter.segmentParagraph('សួស្តី កម្ពុជា');
      expect(spaceTokens.length, 3);
      expect(spaceTokens[1].type, KhmerLayoutTokenType.space);
      expect(spaceTokens[1].isVisible, isTrue);
      expect(spaceTokens[1].isBreakOpportunity, isTrue);

      // NBSP
      final nbspTokens =
          KhmerRunSegmenter.segmentParagraph('សួស្តី\u00A0កម្ពុជា');
      expect(nbspTokens.length, 3);
      expect(nbspTokens[1].type, KhmerLayoutTokenType.nbsp);
      expect(nbspTokens[1].isVisible, isTrue);
      expect(nbspTokens[1].isBreakOpportunity, isFalse);

      // ZWSP
      final zwspTokens =
          KhmerRunSegmenter.segmentParagraph('សួស្តី\u200Bកម្ពុជា');
      expect(zwspTokens.length, 3);
      expect(zwspTokens[1].type, KhmerLayoutTokenType.zwsp);
      expect(zwspTokens[1].isVisible, isFalse);
      expect(zwspTokens[1].isBreakOpportunity, isTrue);
    });
  });
}
