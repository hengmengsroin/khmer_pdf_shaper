// ignore_for_file: avoid_print, camel_case_types, non_constant_identifier_names, unused_local_variable
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

// Native typedefs
typedef hb_blob_create_func = ffi.Pointer<ffi.Opaque> Function(
  ffi.Pointer<ffi.Char> data,
  ffi.UnsignedInt length,
  ffi.Int32 mode,
  ffi.Pointer<ffi.Void> user_data,
  ffi.Pointer<ffi.Void> destroy,
);
typedef HbBlobCreate = ffi.Pointer<ffi.Opaque> Function(
  ffi.Pointer<ffi.Char> data,
  int length,
  int mode,
  ffi.Pointer<ffi.Void> user_data,
  ffi.Pointer<ffi.Void> destroy,
);

typedef hb_blob_destroy_func = ffi.Void Function(ffi.Pointer<ffi.Opaque> blob);
typedef HbBlobDestroy = void Function(ffi.Pointer<ffi.Opaque> blob);

typedef hb_face_create_func = ffi.Pointer<ffi.Opaque> Function(
  ffi.Pointer<ffi.Opaque> blob,
  ffi.UnsignedInt index,
);
typedef HbFaceCreate = ffi.Pointer<ffi.Opaque> Function(
  ffi.Pointer<ffi.Opaque> blob,
  int index,
);

typedef hb_face_destroy_func = ffi.Void Function(ffi.Pointer<ffi.Opaque> face);
typedef HbFaceDestroy = void Function(ffi.Pointer<ffi.Opaque> face);

typedef hb_font_create_func = ffi.Pointer<ffi.Opaque> Function(ffi.Pointer<ffi.Opaque> face);
typedef HbFontCreate = ffi.Pointer<ffi.Opaque> Function(ffi.Pointer<ffi.Opaque> face);

typedef hb_font_destroy_func = ffi.Void Function(ffi.Pointer<ffi.Opaque> font);
typedef HbFontDestroy = void Function(ffi.Pointer<ffi.Opaque> font);

typedef hb_ot_font_set_funcs_func = ffi.Void Function(ffi.Pointer<ffi.Opaque> font);
typedef HbOtFontSetFuncs = void Function(ffi.Pointer<ffi.Opaque> font);

typedef hb_buffer_create_func = ffi.Pointer<ffi.Opaque> Function();
typedef HbBufferCreate = ffi.Pointer<ffi.Opaque> Function();

typedef hb_buffer_destroy_func = ffi.Void Function(ffi.Pointer<ffi.Opaque> buffer);
typedef HbBufferDestroy = void Function(ffi.Pointer<ffi.Opaque> buffer);

typedef hb_buffer_reset_func = ffi.Void Function(ffi.Pointer<ffi.Opaque> buffer);
typedef HbBufferReset = void Function(ffi.Pointer<ffi.Opaque> buffer);

typedef hb_buffer_add_utf16_func = ffi.Void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.Uint16> text,
  ffi.Int text_length,
  ffi.UnsignedInt item_offset,
  ffi.Int item_length,
);
typedef HbBufferAddUtf16 = void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.Uint16> text,
  int text_length,
  int item_offset,
  int item_length,
);

typedef hb_buffer_set_direction_func = ffi.Void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Int32 direction,
);
typedef HbBufferSetDirection = void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  int direction,
);

typedef hb_buffer_set_script_func = ffi.Void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Uint32 script,
);
typedef HbBufferSetScript = void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  int script,
);

typedef hb_buffer_set_language_func = ffi.Void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.Opaque> language,
);
typedef HbBufferSetLanguage = void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.Opaque> language,
);

typedef hb_language_from_string_func = ffi.Pointer<ffi.Opaque> Function(
  ffi.Pointer<ffi.Char> str,
  ffi.Int len,
);
typedef HbLanguageFromString = ffi.Pointer<ffi.Opaque> Function(
  ffi.Pointer<ffi.Char> str,
  int len,
);

typedef hb_tag_from_string_func = ffi.Uint32 Function(
  ffi.Pointer<ffi.Char> str,
  ffi.Int len,
);
typedef HbTagFromString = int Function(
  ffi.Pointer<ffi.Char> str,
  int len,
);

typedef hb_buffer_set_cluster_level_func = ffi.Void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Int32 cluster_level,
);
typedef HbBufferSetClusterLevel = void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  int cluster_level,
);

typedef hb_shape_func = ffi.Void Function(
  ffi.Pointer<ffi.Opaque> font,
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.Void> features,
  ffi.UnsignedInt num_features,
);
typedef HbShape = void Function(
  ffi.Pointer<ffi.Opaque> font,
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.Void> features,
  int num_features,
);

typedef hb_buffer_get_glyph_infos_func = ffi.Pointer<ffi.Void> Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.UnsignedInt> length,
);
typedef HbBufferGetGlyphInfos = ffi.Pointer<ffi.Void> Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.UnsignedInt> length,
);

void main() {
  final dylibPath = '/Users/hengmengsroin/.gemini/antigravity-ide/brain/124ef2f0-1d61-4b71-b0d3-671001f9375b/scratch/libharfbuzz.dylib';
  final dylib = ffi.DynamicLibrary.open(dylibPath);

  final blobCreate = dylib.lookupFunction<hb_blob_create_func, HbBlobCreate>('hb_blob_create');
  final blobDestroy = dylib.lookupFunction<hb_blob_destroy_func, HbBlobDestroy>('hb_blob_destroy');
  final faceCreate = dylib.lookupFunction<hb_face_create_func, HbFaceCreate>('hb_face_create');
  final faceDestroy = dylib.lookupFunction<hb_face_destroy_func, HbFaceDestroy>('hb_face_destroy');
  final fontCreate = dylib.lookupFunction<hb_font_create_func, HbFontCreate>('hb_font_create');
  final fontDestroy = dylib.lookupFunction<hb_font_destroy_func, HbFontDestroy>('hb_font_destroy');
  final otFontSetFuncs = dylib.lookupFunction<hb_ot_font_set_funcs_func, HbOtFontSetFuncs>('hb_ot_font_set_funcs');
  final bufferCreate = dylib.lookupFunction<hb_buffer_create_func, HbBufferCreate>('hb_buffer_create');
  final bufferDestroy = dylib.lookupFunction<hb_buffer_destroy_func, HbBufferDestroy>('hb_buffer_destroy');
  final bufferReset = dylib.lookupFunction<hb_buffer_reset_func, HbBufferReset>('hb_buffer_reset');
  final bufferAddUtf16 = dylib.lookupFunction<hb_buffer_add_utf16_func, HbBufferAddUtf16>('hb_buffer_add_utf16');
  final bufferSetDirection = dylib.lookupFunction<hb_buffer_set_direction_func, HbBufferSetDirection>('hb_buffer_set_direction');
  final bufferSetScript = dylib.lookupFunction<hb_buffer_set_script_func, HbBufferSetScript>('hb_buffer_set_script');
  final bufferSetLanguage = dylib.lookupFunction<hb_buffer_set_language_func, HbBufferSetLanguage>('hb_buffer_set_language');
  final languageFromString = dylib.lookupFunction<hb_language_from_string_func, HbLanguageFromString>('hb_language_from_string');
  final tagFromString = dylib.lookupFunction<hb_tag_from_string_func, HbTagFromString>('hb_tag_from_string');
  final bufferSetClusterLevel = dylib.lookupFunction<hb_buffer_set_cluster_level_func, HbBufferSetClusterLevel>('hb_buffer_set_cluster_level');
  final shape = dylib.lookupFunction<hb_shape_func, HbShape>('hb_shape');
  final bufferGetGlyphInfos = dylib.lookupFunction<hb_buffer_get_glyph_infos_func, HbBufferGetGlyphInfos>('hb_buffer_get_glyph_infos');

  final fontBytes = File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();

  print('=== PART 8: REPEATED SHAPING & PERFORMANCE BENCHMARK ===\n');

  // Cold initialization: Pure Dart
  final swColdDart = Stopwatch()..start();
  final pureDartShaper = BattambangShaper.fromBytes(fontBytes);
  swColdDart.stop();
  print('Pure Dart Cold Initialization (Font parse + GSUB tables): ${swColdDart.elapsedMicroseconds} µs (${swColdDart.elapsedMilliseconds} ms)');

  // Cold initialization: HarfBuzz FFI
  final swColdFfi = Stopwatch()..start();
  final nativeBytes = calloc<ffi.Uint8>(fontBytes.length);
  nativeBytes.asTypedList(fontBytes.length).setAll(0, fontBytes);
  final blob = blobCreate(nativeBytes.cast(), fontBytes.length, 1, ffi.nullptr, ffi.nullptr);
  final face = faceCreate(blob, 0);
  final font = fontCreate(face);
  otFontSetFuncs(font);
  final kmLangStr = 'km'.toNativeUtf8();
  final kmLang = languageFromString(kmLangStr.cast(), -1);
  final khmrTagStr = 'Khmr'.toNativeUtf8();
  final khmrScript = tagFromString(khmrTagStr.cast(), -1);
  swColdFfi.stop();
  print('HarfBuzz FFI Cold Initialization (Blob + Face + Font + Tables): ${swColdFfi.elapsedMicroseconds} µs (${swColdFfi.elapsedMilliseconds} ms)\n');

  final testParagraph = 'សួស្តីពិភពលោក ខ្ញុំស្រឡាញ់ប្រទេសកម្ពុជា។ ភាសាខ្មែរជាភាសាជាតិដ៏ចំណាស់ និងសម្បូរបែប។';
  final codeUnits = testParagraph.codeUnits;
  final utf16Ptr = calloc<ffi.Uint16>(codeUnits.length);
  for (int i = 0; i < codeUnits.length; i++) {
    utf16Ptr[i] = codeUnits[i];
  }

  final iterations = [1, 100, 1000];

  for (final count in iterations) {
    // 1. Warm Pure Dart
    final swDart = Stopwatch()..start();
    for (int i = 0; i < count; i++) {
      pureDartShaper.shapeText(testParagraph);
    }
    swDart.stop();
    final avgDartUs = swDart.elapsedMicroseconds / count;

    // 2. Warm HarfBuzz FFI (reusing buffer via reset)
    final buffer = bufferCreate();
    final lenPtr = calloc<ffi.UnsignedInt>();
    final swFfi = Stopwatch()..start();
    for (int i = 0; i < count; i++) {
      bufferReset(buffer);
      bufferAddUtf16(buffer, utf16Ptr, codeUnits.length, 0, codeUnits.length);
      bufferSetDirection(buffer, 4);
      bufferSetScript(buffer, khmrScript);
      bufferSetLanguage(buffer, kmLang);
      bufferSetClusterLevel(buffer, 0);
      shape(font, buffer, ffi.nullptr, 0);
      bufferGetGlyphInfos(buffer, lenPtr);
    }
    swFfi.stop();
    final avgFfiUs = swFfi.elapsedMicroseconds / count;

    print('--- Benchmark: $count shape() calls (${testParagraph.length} UTF-16 code units) ---');
    print('  Pure Dart:    total ${swDart.elapsedMicroseconds} µs (${swDart.elapsedMilliseconds} ms) | avg: ${avgDartUs.toStringAsFixed(2)} µs/shape');
    print('  HarfBuzz FFI: total ${swFfi.elapsedMicroseconds} µs (${swFfi.elapsedMilliseconds} ms) | avg: ${avgFfiUs.toStringAsFixed(2)} µs/shape');
    print('  Speed ratio:  HarfBuzz FFI is ${(avgDartUs / avgFfiUs).toStringAsFixed(2)}x faster than Pure Dart\n');

    calloc.free(lenPtr);
    bufferDestroy(buffer);
  }

  // Cleanup
  calloc.free(utf16Ptr);
  calloc.free(kmLangStr);
  calloc.free(khmrTagStr);
  fontDestroy(font);
  faceDestroy(face);
  blobDestroy(blob);
  calloc.free(nativeBytes);
}
