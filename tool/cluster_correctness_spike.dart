// ignore_for_file: avoid_print, camel_case_types, non_constant_identifier_names, unused_local_variable
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

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

typedef hb_font_create_func = ffi.Pointer<ffi.Opaque> Function(
    ffi.Pointer<ffi.Opaque> face);
typedef HbFontCreate = ffi.Pointer<ffi.Opaque> Function(
    ffi.Pointer<ffi.Opaque> face);

typedef hb_font_destroy_func = ffi.Void Function(ffi.Pointer<ffi.Opaque> font);
typedef HbFontDestroy = void Function(ffi.Pointer<ffi.Opaque> font);

typedef hb_ot_font_set_funcs_func = ffi.Void Function(
    ffi.Pointer<ffi.Opaque> font);
typedef HbOtFontSetFuncs = void Function(ffi.Pointer<ffi.Opaque> font);

typedef hb_buffer_create_func = ffi.Pointer<ffi.Opaque> Function();
typedef HbBufferCreate = ffi.Pointer<ffi.Opaque> Function();

typedef hb_buffer_destroy_func = ffi.Void Function(
    ffi.Pointer<ffi.Opaque> buffer);
typedef HbBufferDestroy = void Function(ffi.Pointer<ffi.Opaque> buffer);

typedef hb_buffer_add_utf8_func = ffi.Void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.Char> text,
  ffi.Int text_length,
  ffi.UnsignedInt item_offset,
  ffi.Int item_length,
);
typedef HbBufferAddUtf8 = void Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.Char> text,
  int text_length,
  int item_offset,
  int item_length,
);

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

typedef hb_buffer_guess_segment_properties_func = ffi.Void Function(
    ffi.Pointer<ffi.Opaque> buffer);
typedef HbBufferGuessSegmentProperties = void Function(
    ffi.Pointer<ffi.Opaque> buffer);

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

final class HbGlyphInfo extends ffi.Struct {
  @ffi.Uint32()
  external int codepoint;
  @ffi.Uint32()
  external int mask;
  @ffi.Uint32()
  external int cluster;
  @ffi.Uint32()
  external int var1;
  @ffi.Uint32()
  external int var2;
}

final class HbGlyphPosition extends ffi.Struct {
  @ffi.Int32()
  external int x_advance;
  @ffi.Int32()
  external int y_advance;
  @ffi.Int32()
  external int x_offset;
  @ffi.Int32()
  external int y_offset;
  @ffi.Uint32()
  external int var$;
}

typedef hb_buffer_get_glyph_infos_func = ffi.Pointer<HbGlyphInfo> Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.UnsignedInt> length,
);
typedef HbBufferGetGlyphInfos = ffi.Pointer<HbGlyphInfo> Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.UnsignedInt> length,
);

typedef hb_buffer_get_glyph_positions_func = ffi.Pointer<HbGlyphPosition>
    Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.UnsignedInt> length,
);
typedef HbBufferGetGlyphPositions = ffi.Pointer<HbGlyphPosition> Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.UnsignedInt> length,
);

void main() {
  final dylibPath =
      '/Users/hengmengsroin/.gemini/antigravity-ide/brain/124ef2f0-1d61-4b71-b0d3-671001f9375b/scratch/libharfbuzz.dylib';
  final dylib = ffi.DynamicLibrary.open(dylibPath);

  final blobCreate =
      dylib.lookupFunction<hb_blob_create_func, HbBlobCreate>('hb_blob_create');
  final blobDestroy = dylib
      .lookupFunction<hb_blob_destroy_func, HbBlobDestroy>('hb_blob_destroy');
  final faceCreate =
      dylib.lookupFunction<hb_face_create_func, HbFaceCreate>('hb_face_create');
  final faceDestroy = dylib
      .lookupFunction<hb_face_destroy_func, HbFaceDestroy>('hb_face_destroy');
  final fontCreate =
      dylib.lookupFunction<hb_font_create_func, HbFontCreate>('hb_font_create');
  final fontDestroy = dylib
      .lookupFunction<hb_font_destroy_func, HbFontDestroy>('hb_font_destroy');
  final otFontSetFuncs =
      dylib.lookupFunction<hb_ot_font_set_funcs_func, HbOtFontSetFuncs>(
          'hb_ot_font_set_funcs');
  final bufferCreate =
      dylib.lookupFunction<hb_buffer_create_func, HbBufferCreate>(
          'hb_buffer_create');
  final bufferDestroy =
      dylib.lookupFunction<hb_buffer_destroy_func, HbBufferDestroy>(
          'hb_buffer_destroy');
  final bufferAddUtf8 =
      dylib.lookupFunction<hb_buffer_add_utf8_func, HbBufferAddUtf8>(
          'hb_buffer_add_utf8');
  final bufferAddUtf16 =
      dylib.lookupFunction<hb_buffer_add_utf16_func, HbBufferAddUtf16>(
          'hb_buffer_add_utf16');
  final bufferSetDirection =
      dylib.lookupFunction<hb_buffer_set_direction_func, HbBufferSetDirection>(
          'hb_buffer_set_direction');
  final bufferSetScript =
      dylib.lookupFunction<hb_buffer_set_script_func, HbBufferSetScript>(
          'hb_buffer_set_script');
  final bufferSetLanguage =
      dylib.lookupFunction<hb_buffer_set_language_func, HbBufferSetLanguage>(
          'hb_buffer_set_language');
  final languageFromString =
      dylib.lookupFunction<hb_language_from_string_func, HbLanguageFromString>(
          'hb_language_from_string');
  final tagFromString =
      dylib.lookupFunction<hb_tag_from_string_func, HbTagFromString>(
          'hb_tag_from_string');
  final bufferSetClusterLevel = dylib.lookupFunction<
      hb_buffer_set_cluster_level_func,
      HbBufferSetClusterLevel>('hb_buffer_set_cluster_level');
  final bufferGuessProperties = dylib.lookupFunction<
      hb_buffer_guess_segment_properties_func,
      HbBufferGuessSegmentProperties>('hb_buffer_guess_segment_properties');
  final shape = dylib.lookupFunction<hb_shape_func, HbShape>('hb_shape');
  final bufferGetGlyphInfos = dylib.lookupFunction<
      hb_buffer_get_glyph_infos_func,
      HbBufferGetGlyphInfos>('hb_buffer_get_glyph_infos');
  final bufferGetGlyphPositions = dylib.lookupFunction<
      hb_buffer_get_glyph_positions_func,
      HbBufferGetGlyphPositions>('hb_buffer_get_glyph_positions');

  final fontBytes =
      File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
  final nativeBytes = calloc<ffi.Uint8>(fontBytes.length);
  nativeBytes.asTypedList(fontBytes.length).setAll(0, fontBytes);
  final blob = blobCreate(
      nativeBytes.cast(), fontBytes.length, 1, ffi.nullptr, ffi.nullptr);
  final face = faceCreate(blob, 0);
  final font = fontCreate(face);
  otFontSetFuncs(font);

  final kmLangStr = 'km'.toNativeUtf8();
  final kmLang = languageFromString(kmLangStr.cast(), -1);
  final khmrTagStr = 'Khmr'.toNativeUtf8();
  final khmrScript = tagFromString(khmrTagStr.cast(), -1);

  final testCases = [
    ('ក្ក', 'Consonant + Subscript Ka'),
    ('កេ', 'Consonant + Pre-base vowel E (Reordered)'),
    ('ឥក', 'Independent vowel + Consonant'),
    ('ក្្ក', 'Invalid double coeng'),
    ('Aក', 'Latin + Khmer'),
    ('😀ក', 'Surrogate pair emoji (U+1F600) + Khmer'),
    ('ក😀ខ', 'Khmer + Surrogate pair emoji + Khmer'),
  ];

  print('=== PART 6: CLUSTER & UTF-16 / UTF-8 SEMANTICS ===\n');

  for (final (text, label) in testCases) {
    print('--- Case: "$text" ($label) ---');
    print('  Dart String length (UTF-16 code units): ${text.length}');
    print('  Dart codeUnits: ${text.codeUnits}');
    final utf8Bytes = utf8.encode(text);
    print('  UTF-8 byte length: ${utf8Bytes.length}');

    // Test UTF-16 input with MONOTONE_GRAPHEMES (0)
    {
      final buffer = bufferCreate();
      final codeUnits = text.codeUnits;
      final utf16Ptr = calloc<ffi.Uint16>(codeUnits.length);
      for (int i = 0; i < codeUnits.length; i++) {
        utf16Ptr[i] = codeUnits[i];
      }
      bufferAddUtf16(buffer, utf16Ptr, codeUnits.length, 0, codeUnits.length);
      bufferGuessProperties(buffer);
      shape(font, buffer, ffi.nullptr, 0);

      final lengthPtr = calloc<ffi.UnsignedInt>();
      final infos = bufferGetGlyphInfos(buffer, lengthPtr);
      final count = lengthPtr.value;
      final clusters = [
        for (int i = 0; i < count; i++)
          '${infos[i].codepoint}@${infos[i].cluster}'
      ];
      print(
          '  UTF-16 input (default cluster level 0): [${clusters.join(', ')}]');
      calloc.free(lengthPtr);
      calloc.free(utf16Ptr);
      bufferDestroy(buffer);
    }

    // Test UTF-8 input with MONOTONE_GRAPHEMES (0)
    {
      final buffer = bufferCreate();
      final nativeUtf8 = text.toNativeUtf8();
      bufferAddUtf8(buffer, nativeUtf8.cast(), -1, 0, -1);
      bufferGuessProperties(buffer);
      shape(font, buffer, ffi.nullptr, 0);

      final lengthPtr = calloc<ffi.UnsignedInt>();
      final infos = bufferGetGlyphInfos(buffer, lengthPtr);
      final count = lengthPtr.value;
      final clusters = [
        for (int i = 0; i < count; i++)
          '${infos[i].codepoint}@${infos[i].cluster}'
      ];
      print(
          '  UTF-8 input  (default cluster level 0): [${clusters.join(', ')}]');
      calloc.free(lengthPtr);
      calloc.free(nativeUtf8);
      bufferDestroy(buffer);
    }
    print('');
  }

  // Cleanup
  calloc.free(kmLangStr);
  calloc.free(khmrTagStr);
  fontDestroy(font);
  faceDestroy(face);
  blobDestroy(blob);
  calloc.free(nativeBytes);
}
