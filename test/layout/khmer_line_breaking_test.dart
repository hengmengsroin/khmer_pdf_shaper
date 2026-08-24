import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_pdf_shaper/src/layout/khmer_line_breaker.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';

void main() {
  group('Part 6: Line Breaking and Cluster-Safe Wrapping Tests', () {
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

    test('SPACE wraps at space boundary and trims trailing visual whitespace for "សួស្តី កម្ពុជា"', () {
      const text = 'សួស្តី កម្ពុជា';
      const fontSize = 16.0;

      // Full unconstrained width
      final unconstrained = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
      );
      expect(unconstrained.lines.length, 1);
      final fullWidth = unconstrained.width;

      // Constrain maxWidth to slightly less than full width so it must wrap at space
      final wrapped = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
        maxWidth: fullWidth * 0.7,
      );

      expect(wrapped.lines.length, 2);
      expect(wrapped.lines[0].clusters.map((c) => c.text).join(), 'សួស្តី ');
      expect(wrapped.lines[1].clusters.map((c) => c.text).join(), 'កម្ពុជា');

      // Visual width of line 0 excludes the trailing space
      final sLine0Visual = breaker.layout(text: 'សួស្តី', shaper: shaper, fontSize: fontSize).width;
      expect(wrapped.lines[0].visualWidth, closeTo(sLine0Visual, 0.001));
    });

    test('NBSP prevents line break for "សួស្តី\\u00A0កម្ពុជា"', () {
      const text = 'សួស្តី\u00A0កម្ពុជា';
      const fontSize = 16.0;

      final unconstrained = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
      );
      final fullWidth = unconstrained.width;

      // Even if constrained to 70% width, NBSP has breakOpportunity: false, so it cannot break at NBSP
      // Cluster-safe fallback wrapping will only break if entire word exceeds maxWidth
      final wrapped = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
        maxWidth: fullWidth * 0.7,
      );

      // Verify NBSP is preserved and treated as non-breaking
      expect(wrapped.lines.isNotEmpty, isTrue);
      for (final line in wrapped.lines) {
        for (final cluster in line.clusters) {
          if (cluster.text == '\u00A0') {
            expect(cluster.isBreakOpportunity, isFalse);
            expect(cluster.isWhitespace, isFalse);
          }
        }
      }
    });

    test('ZWSP provides invisible break opportunity for "សួស្តី\\u200Bកម្ពុជា"', () {
      const text = 'សួស្តី\u200Bកម្ពុជា';
      const fontSize = 16.0;

      final unconstrained = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
      );
      final fullWidth = unconstrained.width;

      // Constrain to 70% width
      final wrapped = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
        maxWidth: fullWidth * 0.7,
      );

      expect(wrapped.lines.length, 2);
      expect(wrapped.lines[0].clusters.map((c) => c.text).join(), 'សួស្តី\u200B');
      expect(wrapped.lines[1].clusters.map((c) => c.text).join(), 'កម្ពុជា');

      // ZWSP has 0 width
      final zwspCluster = wrapped.lines[0].clusters.last;
      expect(zwspCluster.width, 0.0);
      expect(zwspCluster.isVisible, isFalse);
      expect(zwspCluster.isBreakOpportunity, isTrue);
    });

    test('Wraps mixed script text "Invoice សួស្តី 123" without corrupting runs', () {
      const text = 'Invoice សួស្តី 123';
      const fontSize = 14.0;

      final unconstrained = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
      );
      final fullWidth = unconstrained.width;

      final wrapped = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
        maxWidth: fullWidth * 0.55,
      );

      expect(wrapped.lines.length, 2);
      expect(wrapped.lines[0].clusters.map((c) => c.text).join(), 'Invoice ');
      expect(wrapped.lines[1].clusters.map((c) => c.text).join(), 'សួស្តី 123');
    });

    test('Cluster-safe fallback wrapping for unspaced Khmer "សួស្តីអ្នកទាំងអស់គ្នា"', () {
      const text = 'សួស្តីអ្នកទាំងអស់គ្នា';
      const fontSize = 16.0;

      final unconstrained = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
      );
      expect(unconstrained.lines.length, 1);
      final fullWidth = unconstrained.width;

      // Constrain to half width
      final wrapped = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
        maxWidth: fullWidth * 0.5,
      );

      expect(wrapped.lines.length, greaterThanOrEqualTo(2));

      // Invariant: every single cluster in every line must be an intact ShapingCluster
      for (final line in wrapped.lines) {
        for (final cluster in line.clusters) {
          expect(cluster.glyphs.isNotEmpty, isTrue);
          expect(cluster.text.isNotEmpty, isTrue);
        }
      }

      // Concatenating line texts reproduces the exact original string
      final reconstructed = wrapped.lines.map((l) => l.clusters.map((c) => c.text).join()).join();
      expect(reconstructed, equals(text));
    });

    test('Overlong single cluster does not cause infinite loop on narrow maxWidth', () {
      const text = 'គ្រែ'; // A single complex cluster
      const fontSize = 24.0;

      // Set maxWidth to extremely tiny value (e.g. 2 points, smaller than any cluster)
      final layout = breaker.layout(
        text: text,
        shaper: shaper,
        fontSize: fontSize,
        maxWidth: 2.0,
      );

      // Must terminate immediately and place the cluster on 1 line
      expect(layout.lines.length, 1);
      expect(layout.lines.first.clusters.first.text, 'គ្រែ');
    });
  });
}
