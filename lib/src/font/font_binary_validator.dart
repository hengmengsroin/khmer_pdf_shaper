import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Exception thrown when attempting to parse or shape with an unsupported font artifact.
class UnsupportedFontException implements Exception {
  final String message;
  final String? expectedHash;
  final String? actualHash;

  UnsupportedFontException(this.message, {this.expectedHash, this.actualHash});

  @override
  String toString() {
    if (expectedHash != null && actualHash != null) {
      return 'UnsupportedFontException: $message\nExpected SHA-256: $expectedHash\nActual SHA-256:   $actualHash';
    }
    return 'UnsupportedFontException: $message';
  }
}

/// Font binary validator enforcing the exact frozen Battambang font artifact contract.
class FontBinaryValidator {
  FontBinaryValidator._();

  /// Frozen SHA-256 hash for bundled Battambang-Regular.ttf.
  static const String battambangRegularSha256 =
      'c7d867c7d4e8371f23678bd12cd1700cab1e4e37ec2860eb439766142b240bd9';

  /// Verifies that [bytes] matches the exact supported Battambang font artifact.
  /// Throws [UnsupportedFontException] if the hash does not match or bytes are empty.
  static void verifySupportedFont(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw UnsupportedFontException('Font byte buffer is empty.');
    }
    final digest = sha256.convert(bytes);
    final hash = digest.toString().toLowerCase();
    if (hash != battambangRegularSha256) {
      throw UnsupportedFontException(
        'Font binary validation failed. Mismatching font bytes cannot be processed by this frozen shaper.',
        expectedHash: battambangRegularSha256,
        actualHash: hash,
      );
    }
  }
}
