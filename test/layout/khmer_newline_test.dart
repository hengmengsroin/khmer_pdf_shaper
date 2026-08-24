import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/layout/khmer_line_breaker.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('Part 5: Explicit Newlines Tests', () {
    late Uint8List fontBytes;
    late BattambangShaper shaper;
    late KhmerLineBreaker breaker;

    setUpAll(() {
      final file = File('assets/fonts/Battambang-Regular.ttf');
      expect(file.existsSync(), isTrue);
      fontBytes = file.readAsBytesSync();
      shaper = BattambangShaper.fromBytes(fontBytes);
      breaker = const KhmerLineBreaker();
    });

    test('Handles explicit \\n forced line break for "សួស្តី\\nកម្ពុជា"', () {
      const text = 'សួស្តី\nកម្ពុជា';
      final layout = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: 16.0,
      );

      expect(layout.lines.length, 2);

      final line0 = layout.lines[0];
      final line1 = layout.lines[1];

      // Verify line 0 content and source mapping
      expect(line0.clusters.map((c) => c.text).join(), 'សួស្តី');
      expect(line0.sourceStart, 0);
      expect(line0.sourceEnd, 6);

      // Verify line 1 content and source mapping
      expect(line1.clusters.map((c) => c.text).join(), 'កម្ពុជា');
      expect(line1.sourceStart, 7);
      expect(line1.sourceEnd, 14);
    });

    test(
        'Normalizes \\r\\n to single forced line break for "សួស្តី\\r\\nកម្ពុជា"',
        () {
      const text = 'សួស្តី\r\nកម្ពុជា';
      final layout = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: 16.0,
      );

      expect(layout.lines.length, 2);

      final line0 = layout.lines[0];
      final line1 = layout.lines[1];

      expect(line0.clusters.map((c) => c.text).join(), 'សួស្តី');
      expect(line1.clusters.map((c) => c.text).join(), 'កម្ពុជា');
    });

    test('Handles multiple consecutive newlines for "សួស្តី\\n\\nកម្ពុជា"', () {
      const text = 'សួស្តី\n\nកម្ពុជា';
      final layout = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: 16.0,
      );

      expect(layout.lines.length, 3);

      final line0 = layout.lines[0];
      final line1 = layout.lines[1];
      final line2 = layout.lines[2];

      expect(line0.clusters.map((c) => c.text).join(), 'សួស្តី');
      expect(line1.clusters.isEmpty, isTrue);
      expect(line1.visualWidth, 0.0);
      expect(line2.clusters.map((c) => c.text).join(), 'កម្ពុជា');

      // Total height is exactly 3 * lineHeight
      expect(layout.height, closeTo(3 * layout.lineHeight, 0.0001));
    });

    test('Ensures newlines are not included in shaping clusters', () {
      const text = 'សួស្តី\nកម្ពុជា';
      final layout = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: 16.0,
      );

      for (final line in layout.lines) {
        for (final cluster in line.clusters) {
          expect(cluster.text, isNot(contains('\n')));
          expect(cluster.text, isNot(contains('\r')));
        }
      }
    });
  });
}
