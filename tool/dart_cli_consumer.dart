import 'dart:io';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  print('Running pure Dart CLI PDF generation...');
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(
            level: 0,
            text: 'Dart CLI Khmer PDF Generator',
          ),
          pw.SizedBox(height: 10),
          KhmerText(
            'សួស្តីពិភពលោក! នេះជាការបង្កើតឯកសារ PDF ដោយប្រើប្រាស់ Pure Dart CLI។',
            style: const pw.TextStyle(fontSize: 18),
          ),
          pw.SizedBox(height: 10),
          KhmerText(
            'Invoice សួស្តី 123 - Total: \$50.00 រៀល',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 15),
          KhmerText(
            'កម្ពុជា ប្រទេសដ៏ស្រស់បំព្រង មានប្រាង្គប្រាសាទបុរាណជាច្រើន។',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );

  final bytes = await pdf.save();
  final outDir = Directory('.dart_tool/cli_output');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }
  final outFile = File('${outDir.path}/cli_khmer_demo.pdf');
  outFile.writeAsBytesSync(bytes);

  print(
      'Successfully generated ${bytes.length} bytes PDF via Dart CLI: ${outFile.path}');
}
