import 'dart:io';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:khmer_pdf_shaper/src/font/battambang_font_data.dart';
import 'package:khmer_pdf_shaper/src/layout/khmer_line_breaker.dart';
import 'package:khmer_pdf_shaper/src/shaper/battambang_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  print('=== Phase 7 — Performance Regression Baselines ===\n');

  final fontBytes = getBundledBattambangBytes();
  final shaper = BattambangShaper.fromBytes(fontBytes);
  const breaker = KhmerLineBreaker();

  const shortWord = 'សួស្តី';
  const shortParagraph =
      'ភាសាខ្មែរ គឺជាភាសាផ្លូវការរបស់ប្រទេសកម្ពុជា '
      'ហើយត្រូវបានប្រើប្រាស់ដោយប្រជាជនខ្មែរទូទាំងពិភពលោក។ '
      'ការបង្កើតឯកសារ PDF ជាភាសាខ្មែរត្រូវតែមានភាពត្រឹមត្រូវតាមក្បួនខ្នាត។';

  // 1. Benchmark: Shape short word
  {
    // Warmup
    for (int i = 0; i < 1000; i++) {
      shaper.shapeText(shortWord);
    }
    const iterations = 10000;
    final sw = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      shaper.shapeText(shortWord);
    }
    sw.stop();
    final avgUs = sw.elapsedMicroseconds / iterations;
    print('1. Shape short word ("$shortWord"):');
    print('   Total time: ${sw.elapsedMilliseconds} ms ($iterations iterations)');
    print('   Average:    ${avgUs.toStringAsFixed(2)} µs / word\n');
  }

  // 2. Benchmark: Layout short paragraph
  {
    // Warmup
    for (int i = 0; i < 500; i++) {
      breaker.layout(
        text: shortParagraph,
        shaper: shaper,
        fontSize: 12.0,
        maxWidth: 300.0,
      );
    }
    const iterations = 2000;
    final sw = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      breaker.layout(
        text: shortParagraph,
        shaper: shaper,
        fontSize: 12.0,
        maxWidth: 300.0,
      );
    }
    sw.stop();
    final avgUs = sw.elapsedMicroseconds / iterations;
    print('2. Layout short paragraph (${shortParagraph.length} chars, 300pt maxWidth):');
    print('   Total time: ${sw.elapsedMilliseconds} ms ($iterations iterations)');
    print('   Average:    ${avgUs.toStringAsFixed(2)} µs / layout (${(avgUs / 1000).toStringAsFixed(3)} ms)\n');
  }

  // 3. Benchmark: Generate 1-page PDF
  {
    // Warmup
    for (int i = 0; i < 10; i++) {
      final p = pw.Document();
      p.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => KhmerText(shortParagraph, style: const pw.TextStyle(fontSize: 12)),
        ),
      );
      await p.save();
    }

    const iterations = 100;
    final sw = Stopwatch()..start();
    int totalBytes = 0;
    for (int i = 0; i < iterations; i++) {
      final p = pw.Document();
      p.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Column(
            children: [
              KhmerText('ព្រះរាជាណាចក្រកម្ពុជា', style: const pw.TextStyle(fontSize: 18)),
              KhmerText('Invoice សួស្តី 123', style: const pw.TextStyle(fontSize: 12)),
              KhmerText(shortParagraph, style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
      final b = await p.save();
      totalBytes = b.length;
    }
    sw.stop();
    final avgMs = sw.elapsedMilliseconds / iterations;
    print('3. Generate 1-page PDF:');
    print('   Total time: ${sw.elapsedMilliseconds} ms ($iterations PDFs generated)');
    print('   Average:    ${avgMs.toStringAsFixed(2)} ms / PDF');
    print('   PDF size:   $totalBytes bytes\n');
  }

  // 4. Benchmark: Generate 100-page PDF
  {
    final sw = Stopwatch()..start();
    final pdf = pw.Document();
    for (int page = 1; page <= 100; page++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              KhmerText('ទំព័រទី $page ៖ របាយការណ៍បច្ចេកទេស', style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              KhmerText(shortParagraph, style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
        ),
      );
    }
    final bytes = await pdf.save();
    sw.stop();
    print('4. Generate 100-page PDF:');
    print('   Total time: ${sw.elapsedMilliseconds} ms');
    print('   PDF size:   ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(1)} KB)\n');
  }

  print('Peak/Current Process RSS: ${(ProcessInfo.currentRss / (1024 * 1024)).toStringAsFixed(2)} MB');
}
