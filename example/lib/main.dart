import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:khmer_pdf_shaper/khmer_pdf_shaper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: KhmerPdfExample(),
  ));
}

class KhmerPdfExample extends StatelessWidget {
  const KhmerPdfExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khmer PDF Shaper Demo'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Centered Main Title
                pw.Center(
                  child: KhmerText(
                    'ព្រះរាជាណាចក្រកម្ពុជា',
                    style: pw.TextStyle(
                      fontSize: 22,
                      color: PdfColors.indigo900,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Center(
                  child: KhmerText(
                    'ជាតិ សាសនា ព្រះមហាក្សត្រ',
                    style: const pw.TextStyle(fontSize: 16),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.indigo300),
                pw.SizedBox(height: 12),

                // Mixed Script Section
                KhmerText(
                  'Invoice សួស្តី 123',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.blueGrey800,
                    font: pw.Font.helveticaBold(),
                  ),
                ),
                pw.SizedBox(height: 6),
                KhmerText(
                  'Price: \$10.50 កម្ពុជា | Total: \$21.00 រៀល',
                  style: const pw.TextStyle(fontSize: 13),
                ),
                pw.SizedBox(height: 16),

                // Multi-line wrapped paragraph
                KhmerText(
                  'ការពិពណ៌នា៖ ភាសាខ្មែរ គឺជាភាសាផ្លូវការរបស់ប្រទេសកម្ពុជា '
                  'ដែលត្រូវបានប្រើប្រាស់ដោយប្រជាជនខ្មែររាប់លាននាក់។ '
                  'កម្មវិធី Khmer PDF Shaper នេះជួយសម្រួលដល់ការបង្កើតឯកសារ PDF '
                  'ឲ្យមានសោភ័ណភាពស្រស់ស្អាត ត្រឹមត្រូវតាមក្បួនខ្នាតអក្ខរាវិរុទ្ធខ្មែរ '
                  'និងអាចស្វែងរក (Search) ឬចម្លង (Copy-Paste) អក្សរបានយ៉ាងរលូន។',
                  style: const pw.TextStyle(fontSize: 12),
                  lineHeightFactor: 1.6,
                ),
                pw.SizedBox(height: 20),

                // Alignment demonstrations
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.grey100,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      KhmerText(
                        'តម្រឹមឆ្វេង៖ សួស្តីកម្ពុជា',
                        style: const pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.left,
                      ),
                      KhmerText(
                        'តម្រឹមកណ្តាល៖ ខ្ញុំស្រឡាញ់ភាសាខ្មែរ',
                        style: const pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center,
                      ),
                      KhmerText(
                        'តម្រឹមស្តាំ៖ អរគុណសន្តិភាព',
                        style: const pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),

                pw.Divider(),
                KhmerText(
                  'Generated with pure Dart khmer_pdf_shaper',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
