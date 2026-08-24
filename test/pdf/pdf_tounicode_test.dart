import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:khmer_pdf_shaper/src/pdf/khmer_tounicode_cmap.dart';

void main() {
  group('KhmerToUnicodeCmap Tests', () {
    test('Generates valid Adobe ToUnicode CMap with multi-character UTF-16 hex values and empty mappings', () {
      final doc = PdfDocument();
      final mapping = <int, String>{
        1: 'ក្រ', // U+1780 U+17D2 U+179A
        2: '',   // Secondary glyph -> explicit empty mapping <>
        3: 'ក្ក', // U+1780 U+17D2 U+1780
      };

      final cmap = KhmerToUnicodeCmap(doc, cidToUnicode: mapping);
      cmap.prepare();

      final output = utf8.decode(cmap.buf.output());

      expect(output, contains('/CMapName /Adobe-Identity-UCS def'));
      expect(output, contains('/CMapType 2 def'));
      expect(output, contains('1 begincodespacerange'));
      expect(output, contains('<0000> <FFFF>'));
      expect(output, contains('endcodespacerange'));

      expect(output, contains('3 beginbfchar'));
      expect(output, contains('<0001> <178017D2179A>'));
      expect(output, contains('<0002> <>'));
      expect(output, contains('<0003> <178017D21780>'));
      expect(output, contains('endbfchar'));
      expect(output, contains('endcmap'));
    });

    test('Splits entries into multiple blocks of <= 100 entries per CMap specification', () {
      final doc = PdfDocument();
      final mapping = <int, String>{};

      // Generate 250 test entries
      for (int i = 1; i <= 250; i++) {
        mapping[i] = 'ក';
      }

      final cmap = KhmerToUnicodeCmap(doc, cidToUnicode: mapping);
      cmap.prepare();

      final output = utf8.decode(cmap.buf.output());

      // Should have 3 beginbfchar blocks: 100, 100, 50
      expect(output, contains('100 beginbfchar'));
      expect(output, contains('50 beginbfchar'));
      expect(output.split('beginbfchar').length - 1, equals(3));
      expect(output.split('endbfchar').length - 1, equals(3));
    });
  });
}
