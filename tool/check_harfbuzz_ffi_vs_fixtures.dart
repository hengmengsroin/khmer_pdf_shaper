// ignore_for_file: avoid_print, camel_case_types, non_constant_identifier_names, unused_local_variable
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:tamil_pdf_shaper/src/shaper/battambang_shaper.dart';

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

typedef hb_buffer_get_glyph_positions_func = ffi.Pointer<HbGlyphPosition> Function(
  ffi.Pointer<ffi.Opaque> buffer,
  ffi.Pointer<ffi.UnsignedInt> length,
);
typedef HbBufferGetGlyphPositions = ffi.Pointer<HbGlyphPosition> Function(
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
  final bufferAddUtf16 = dylib.lookupFunction<hb_buffer_add_utf16_func, HbBufferAddUtf16>('hb_buffer_add_utf16');
  final bufferSetDirection = dylib.lookupFunction<hb_buffer_set_direction_func, HbBufferSetDirection>('hb_buffer_set_direction');
  final bufferSetScript = dylib.lookupFunction<hb_buffer_set_script_func, HbBufferSetScript>('hb_buffer_set_script');
  final bufferSetLanguage = dylib.lookupFunction<hb_buffer_set_language_func, HbBufferSetLanguage>('hb_buffer_set_language');
  final languageFromString = dylib.lookupFunction<hb_language_from_string_func, HbLanguageFromString>('hb_language_from_string');
  final tagFromString = dylib.lookupFunction<hb_tag_from_string_func, HbTagFromString>('hb_tag_from_string');
  final bufferSetClusterLevel = dylib.lookupFunction<hb_buffer_set_cluster_level_func, HbBufferSetClusterLevel>('hb_buffer_set_cluster_level');
  final shape = dylib.lookupFunction<hb_shape_func, HbShape>('hb_shape');
  final bufferGetGlyphInfos = dylib.lookupFunction<hb_buffer_get_glyph_infos_func, HbBufferGetGlyphInfos>('hb_buffer_get_glyph_infos');
  final bufferGetGlyphPositions = dylib.lookupFunction<hb_buffer_get_glyph_positions_func, HbBufferGetGlyphPositions>('hb_buffer_get_glyph_positions');

  final fontBytes = File('assets/fonts/Battambang-Regular.ttf').readAsBytesSync();
  final pureDartShaper = BattambangShaper.fromBytes(fontBytes);

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

  final fixtureFile = File('test/fixtures/khmer_golden_fixtures.json');
  final jsonCorpus = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
  final fixtures = jsonCorpus['fixtures'] as List<dynamic>;

  int ffiMatches = 0;
  int ffiMismatches = 0;
  int pureDartMatches = 0;
  int pureDartMismatches = 0;

  final ffiMismatchDetails = <String>[];
  final pureDartMismatchDetails = <String>[];

  for (final f in fixtures) {
    final id = f['id'] as String;
    final text = f['text'] as String;
    final expectedGlyphs = f['harfbuzz']['glyphs'] as List<dynamic>;

    // 1. Pure Dart Shaper
    final pureRun = pureDartShaper.shapeText(text);
    bool pureMatches = true;
    if (pureRun.glyphs.length != expectedGlyphs.length) {
      pureMatches = false;
      pureDartMismatchDetails.add('$id: count mismatch pure=${pureRun.glyphs.length} exp=${expectedGlyphs.length}');
    } else {
      for (int i = 0; i < pureRun.glyphs.length; i++) {
        final actual = pureRun.glyphs[i];
        final exp = expectedGlyphs[i];
        if (actual.glyphId != exp['glyph_id'] ||
            actual.cluster != exp['cluster'] ||
            (actual.xAdvance - (exp['x_advance'] as num)).abs() > 0.001 ||
            (actual.yAdvance - (exp['y_advance'] as num)).abs() > 0.001 ||
            (actual.xOffset - (exp['x_offset'] as num)).abs() > 0.001 ||
            (actual.yOffset - (exp['y_offset'] as num)).abs() > 0.001) {
          pureMatches = false;
          pureDartMismatchDetails.add('$id glyph $i mismatch: pure=$actual, exp=$exp');
          break;
        }
      }
    }
    if (pureMatches) {
      pureDartMatches++;
    } else {
      pureDartMismatches++;
    }

    // 2. HarfBuzz FFI Shaper
    final buffer = bufferCreate();
    final codeUnits = text.codeUnits;
    final utf16Ptr = calloc<ffi.Uint16>(codeUnits.length);
    for (int i = 0; i < codeUnits.length; i++) {
      utf16Ptr[i] = codeUnits[i];
    }
    bufferAddUtf16(buffer, utf16Ptr, codeUnits.length, 0, codeUnits.length);
    bufferSetDirection(buffer, 4); // HB_DIRECTION_LTR
    bufferSetScript(buffer, khmrScript);
    bufferSetLanguage(buffer, kmLang);
    bufferSetClusterLevel(buffer, 0); // HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES = 0

    shape(font, buffer, ffi.nullptr, 0);

    final lengthPtr = calloc<ffi.UnsignedInt>();
    final infos = bufferGetGlyphInfos(buffer, lengthPtr);
    final positions = bufferGetGlyphPositions(buffer, lengthPtr);
    final count = lengthPtr.value;

    bool ffiMatch = true;
    if (count != expectedGlyphs.length) {
      ffiMatch = false;
      ffiMismatchDetails.add('$id: count mismatch ffi=$count exp=${expectedGlyphs.length}');
    } else {
      for (int i = 0; i < count; i++) {
        final info = infos[i];
        final pos = positions[i];
        final exp = expectedGlyphs[i];
        if (info.codepoint != exp['glyph_id'] ||
            info.cluster != exp['cluster'] ||
            pos.x_advance != exp['x_advance'] ||
            pos.y_advance != exp['y_advance'] ||
            pos.x_offset != exp['x_offset'] ||
            pos.y_offset != exp['y_offset']) {
          ffiMatch = false;
          ffiMismatchDetails.add('$id glyph $i mismatch: ffi=(gid:${info.codepoint}, cl:${info.cluster}, adv:(${pos.x_advance},${pos.y_advance}), off:(${pos.x_offset},${pos.y_offset})) vs exp=$exp');
          break;
        }
      }
    }
    if (ffiMatch) {
      ffiMatches++;
    } else {
      ffiMismatches++;
    }

    calloc.free(lengthPtr);
    calloc.free(utf16Ptr);
    bufferDestroy(buffer);
  }

  print('\n=== PART 4: 206 RETAINED FIXTURES COMPARISON ===');
  print('Total fixtures: ${fixtures.length}');
  print('FFI vs Oracle:        $ffiMatches exact, $ffiMismatches failed');
  print('Pure Dart vs Oracle:  $pureDartMatches exact, $pureDartMismatches failed');

  if (ffiMismatchDetails.isNotEmpty) {
    print('\nFFI Mismatch Details (${ffiMismatchDetails.length}):');
    for (final d in ffiMismatchDetails.take(10)) {
      print('  $d');
    }
  }

  if (pureDartMismatchDetails.isNotEmpty) {
    print('\nPure Dart Mismatch Details (${pureDartMismatchDetails.length}):');
    for (final d in pureDartMismatchDetails.take(10)) {
      print('  $d');
    }
  }

  // Cleanup
  calloc.free(kmLangStr);
  calloc.free(khmrTagStr);
  fontDestroy(font);
  faceDestroy(face);
  blobDestroy(blob);
  calloc.free(nativeBytes);
}
