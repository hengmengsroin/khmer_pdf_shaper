import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_pdf_shaper/src/font/font_binary_validator.dart';

void main() {
  group('Part 1: Font Binary Validation Tests', () {
    late Uint8List validFontBytes;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue, reason: 'Battambang font file must exist');
      validFontBytes = file.readAsBytesSync();
    });

    test('Validates exact bundled Battambang-Regular.ttf hash', () {
      expect(
        () => FontBinaryValidator.verifySupportedFont(validFontBytes),
        returnsNormally,
      );
    });

    test('Rejects empty font buffer', () {
      expect(
        () => FontBinaryValidator.verifySupportedFont(Uint8List(0)),
        throwsA(isA<UnsupportedFontException>()),
      );
    });

    test('Rejects corrupted or altered font bytes', () {
      final corrupted = Uint8List.fromList(validFontBytes);
      corrupted[100] ^= 0xFF; // Flip byte
      expect(
        () => FontBinaryValidator.verifySupportedFont(corrupted),
        throwsA(isA<UnsupportedFontException>()),
      );
    });

    test('Rejects other font files (e.g. Anand_MuktaMalar.ttf)', () {
      final otherFontFile = File('assets/fonts/Anand_MuktaMalar.ttf');
      if (otherFontFile.existsSync()) {
        final otherBytes = otherFontFile.readAsBytesSync();
        expect(
          () => FontBinaryValidator.verifySupportedFont(otherBytes),
          throwsA(isA<UnsupportedFontException>()),
        );
      }
    });
  });
}
