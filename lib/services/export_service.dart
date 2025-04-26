import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';

import '../models/document_model.dart';
import 'platform_service.dart';
// import 'quill_pdf_converter_fixed.dart';
import 'quill_pdf_converter.dart';

enum ExportFormat {
  pdf,
  plainText,
  html,
  markdown,
}

class ExportService {
  // Export a document to the specified format
  static Future<bool> exportDocument(
      BuildContext context, DocumentModel document, ExportFormat format) async {
    try {
      switch (format) {
        case ExportFormat.pdf:
          return await _exportToPdf(context, document);
        case ExportFormat.plainText:
          return await _exportToPlainText(context, document);
        case ExportFormat.html:
          return await _exportToHtml(context, document);
        case ExportFormat.markdown:
          return await _exportToMarkdown(context, document);
      }
    } catch (e) {
      debugPrint('Error exporting document: $e');
      // Show an error dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting document: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Export to PDF format
  static Future<bool> _exportToPdf(
      BuildContext context, DocumentModel document) async {
    // Create a PDF document
    final pdf = pw.Document();

    // Get a Quill controller from the document
    final quillController = document.toQuillController();

    // Convert Quill document to PDF widgets
    final pdfWidgets =
        await quillDocumentToPdfWidgets(quillController.document);

    // Calculate how many widgets to put on each page (approximate pagination)
    const int widgetsPerPage = 30; // Adjust based on content density

    // Create pages with proper pagination
    for (int i = 0; i < pdfWidgets.length; i += widgetsPerPage) {
      final pageWidgets = pdfWidgets.sublist(
          i,
          i + widgetsPerPage < pdfWidgets.length
              ? i + widgetsPerPage
              : pdfWidgets.length);

      // Add a page with content
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Only show title on the first page
                if (i == 0) ...[
                  pw.Text(
                    document.title,
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                ],
                // Add content widgets for this page
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: pageWidgets,
                  ),
                ),
                // Add page number at the bottom
                pw.Footer(
                  trailing: pw.Text(
                    'Page ${(i ~/ widgetsPerPage) + 1} of ${(pdfWidgets.length / widgetsPerPage).ceil()}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Save the PDF
    final bytes = await pdf.save();

    return await _saveFile(
        context, bytes, '${document.title}.pdf', 'application/pdf');
  }

  // Export to plain text format
  static Future<bool> _exportToPlainText(
      BuildContext context, DocumentModel document) async {
    // Get a Quill controller from the document
    final quillController = document.toQuillController();

    // Extract the plain text
    final text = quillController.document.toPlainText();

    // Convert to bytes
    final bytes = Uint8List.fromList(utf8.encode(text));

    return await _saveFile(
        context, bytes, '${document.title}.txt', 'text/plain');
  }

  // Export to HTML format
  static Future<bool> _exportToHtml(
      BuildContext context, DocumentModel document) async {
    // Get a Quill controller from the document
    final quillController = document.toQuillController();

    // Extract as HTML - SimpleConverter is used to convert to HTML
    // This is a simplified approach that doesn't handle all formatting
    final text = quillController.document.toPlainText();
    String html = '''<div>${text.replaceAll('\n', '<br/>')}</div>''';

    // Add basic HTML structure
    html = '''
<!DOCTYPE html>
<html>
<head>
  <title>${document.title}</title>
  <meta charset="utf-8">
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      margin: 40px;
    }
    h1 {
      color: #333;
    }
  </style>
</head>
<body>
  <h1>${document.title}</h1>
  $html
</body>
</html>
''';

    // Convert to bytes
    final bytes = Uint8List.fromList(utf8.encode(html));

    return await _saveFile(
        context, bytes, '${document.title}.html', 'text/html');
  }

  // Export to Markdown format
  static Future<bool> _exportToMarkdown(
      BuildContext context, DocumentModel document) async {
    // Get a Quill controller from the document
    final quillController = document.toQuillController();

    // We'll convert to a simple Markdown format
    // This is a simplified conversion and might not handle all formatting
    final text = quillController.document.toPlainText();

    // Add a markdown title
    final markdown = '# ${document.title}\n\n$text';

    // Convert to bytes
    final bytes = Uint8List.fromList(utf8.encode(markdown));

    return await _saveFile(
        context, bytes, '${document.title}.md', 'text/markdown');
  }

  // Save file to disk (handles platform differences)
  static Future<bool> _saveFile(BuildContext context, Uint8List bytes,
      String fileName, String mimeType) async {
    try {
      if (kIsWeb) {
        // On web, download the file using file_saver
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          mimeType: MimeType.other,
          ext: path.extension(fileName).replaceFirst('.', ''),
        );
        return true;
      } else if (PlatformService.isDesktopPlatform()) {
        // On desktop, use file_picker to choose save location
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Your Document',
          fileName: fileName,
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
          return true;
        }
        return false;
      } else {
        // On mobile, save to app's documents directory and prompt user
        final result = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          mimeType: MimeType.other,
          ext: path.extension(fileName).replaceFirst('.', ''),
        );
        return result.isNotEmpty;
      }
    } catch (e) {
      debugPrint('Error saving file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Preview PDF before saving
  static Future<void> previewPdf(
      BuildContext context, DocumentModel document) async {
    // Create a PDF document
    final pdf = pw.Document();

    // Get a Quill controller from the document
    final quillController = document.toQuillController();

    // Extract the plain text
    final text = quillController.document.toPlainText();

    // Create a PDF page with the text
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                document.title,
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(text),
            ],
          );
        },
      ),
    );

    // Get PDF bytes
    final bytes = await pdf.save();

    // Show print preview
    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: document.title,
      );
    }
  }
}
