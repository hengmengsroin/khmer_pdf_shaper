import 'dart:convert';
import 'dart:io';

void main() {
  final fontFile = File('assets/fonts/Battambang-Regular.ttf');
  final bytes = fontFile.readAsBytesSync();
  final b64 = base64Encode(bytes);

  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln(
      '// Bundled Battambang-Regular.ttf font binary encoded in pure Dart.');
  buffer.writeln();
  buffer.writeln("import 'dart:convert';");
  buffer.writeln("import 'dart:typed_data';");
  buffer.writeln("import 'font_binary_validator.dart';");
  buffer.writeln();
  buffer.writeln('Uint8List? _cachedBattambangBytes;');
  buffer.writeln();
  buffer.writeln(
      '/// Returns the bundled Battambang-Regular font bytes as a [Uint8List].');
  buffer.writeln(
      '/// Decoded on-demand once and cached in memory with SHA-256 validation.');
  buffer.writeln('Uint8List getBundledBattambangBytes() {');
  buffer.writeln(
      '  if (_cachedBattambangBytes != null) return _cachedBattambangBytes!;');
  buffer.writeln('  final decoded = base64Decode(_kBattambangBase64);');
  buffer.writeln('  FontBinaryValidator.verifySupportedFont(decoded);');
  buffer.writeln('  _cachedBattambangBytes = decoded;');
  buffer.writeln('  return decoded;');
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('const String _kBattambangBase64 =');
  // Write in 80-char chunks for clean source formatting
  const chunkSize = 80;
  for (int i = 0; i < b64.length; i += chunkSize) {
    final end = (i + chunkSize < b64.length) ? i + chunkSize : b64.length;
    final chunk = b64.substring(i, end);
    if (end < b64.length) {
      buffer.writeln("    '$chunk'");
    } else {
      buffer.writeln("    '$chunk';");
    }
  }

  File('lib/src/font/battambang_font_data.dart')
      .writeAsStringSync(buffer.toString());
  print(
      'Generated lib/src/font/battambang_font_data.dart successfully (${bytes.length} bytes -> ${b64.length} chars).');
}
