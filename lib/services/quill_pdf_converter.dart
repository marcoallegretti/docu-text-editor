import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter/foundation.dart';

/// Converts a Quill document to a list of pw.Widget for PDF rendering, preserving formatting.
Future<List<pw.Widget>> quillDocumentToPdfWidgets(quill.Document doc) async {
  // Load standard PDF fonts with support for different styles
  final fontRegular = pw.Font.helvetica();
  final fontBold = pw.Font.helveticaBold();
  final fontItalic = pw.Font.helveticaOblique();
  final fontBoldItalic = pw.Font.helveticaBoldOblique();

  final widgets = <pw.Widget>[];
  final delta = doc.toDelta();

  // Track current list state
  String? currentListType;
  int currentListNumber = 1;
  int currentIndentLevel = 0;

  // Process each operation in the delta
  List<Map<String, dynamic>> currentLine = [];

  // Helper function to create a text segment with formatting
  Map<String, dynamic> createTextSegment(
      String text, Map<String, dynamic> attrs) {
    return {
      'text': text,
      'bold': attrs['bold'] == true,
      'italic': attrs['italic'] == true,
      'underline': attrs['underline'] == true,
      'strike': attrs['strike'] == true,
      'color': attrs['color'],
      'size': attrs['size'], // capture font size
    };
  }

  // Process each operation
  for (final op in delta.toList()) {
    if (!op.isInsert) continue;

    final data = op.data;
    final attrs = op.attributes ?? {};

    if (data is String) {
      // --- Handle embedded line breaks in text segments ---
      final lines = data.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final isLast = i == lines.length - 1;
        if (line.isNotEmpty) {
          // Add non-empty part to current line
          currentLine.add(createTextSegment(line, attrs));
        }
        if (!isLast) {
          // Flush currentLine as a line break
          if (attrs.containsKey('list')) {
            // Handle list item (same as before)
            final listType = attrs['list'] as String;
            final indent = attrs['indent'] as int? ?? 0;
            if (currentListType != listType || currentIndentLevel != indent) {
              if (listType == 'ordered') {
                currentListNumber = 1;
              }
              currentListType = listType;
              currentIndentLevel = indent;
            }
            // Only render a list item if the currentLine contains visible text
            final hasContent = currentLine.any((segment) =>
                (segment['text']?.toString().trim().isNotEmpty ?? false));
            if (!hasContent) {
              widgets.add(
                pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text('',
                      style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                ),
              );
              currentLine = [];
              continue;
            }
            // Extract font size and alignment from attrs
            double fontSize = 12;
            if (attrs.containsKey('size')) {
              final sizeAttr = attrs['size'];
              fontSize = _mapFontSize(sizeAttr);
            }
            final align = attrs['align'] as String?;
            final String marker =
                listType == 'bullet' ? '-' : '${currentListNumber++}.';
            final indentWidth = indent * 15.0;
            final contentSpans = _buildStyledTextSpans(
                currentLine, fontRegular, fontBold, fontItalic, fontBoldItalic,
                defaultFontSize: fontSize);
            widgets.add(
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 4),
                child: pw.SizedBox(
                  width: double.infinity,
                  child: pw.Table(
                    border: null,
                    columnWidths: {
                      0: pw.FixedColumnWidth(indentWidth),
                      1: pw.FixedColumnWidth(listType == 'bullet' ? 15 : 25),
                      2: pw.FlexColumnWidth(),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.SizedBox(width: indentWidth),
                          pw.Container(
                            alignment: pw.Alignment.topRight,
                            padding: pw.EdgeInsets.only(right: 8),
                            child: pw.Text(
                              marker,
                              style: pw.TextStyle(
                                  font: fontRegular, fontSize: fontSize),
                            ),
                          ),
                          pw.RichText(
                            textAlign: _getTextAlign(align),
                            text: pw.TextSpan(
                              style: pw.TextStyle(
                                  font: fontRegular, fontSize: fontSize),
                              children: contentSpans,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (attrs.containsKey('header')) {
            final level = attrs['header'] as int? ?? 1;
            final fontSize = _getHeaderFontSize(level);
            final align = attrs['align'] as String?;
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 12, bottom: 8),
                child: pw.SizedBox(
                  width: double.infinity,
                  child: pw.RichText(
                    textAlign: _getTextAlign(align),
                    text: pw.TextSpan(
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: fontSize,
                      ),
                      children: _buildStyledTextSpans(
                        currentLine,
                        fontRegular,
                        fontBold,
                        fontItalic,
                        fontBoldItalic,
                        defaultFontSize: fontSize,
                        defaultFont: fontBold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            // Regular paragraph
            double fontSize = 12;
            if (attrs.containsKey('size')) {
              final sizeAttr = attrs['size'];
              fontSize = _mapFontSize(sizeAttr);
            }
            final align = attrs['align'] as String?;
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.SizedBox(
                  width: double.infinity,
                  child: pw.RichText(
                    textAlign: _getTextAlign(align),
                    text: pw.TextSpan(
                      style:
                          pw.TextStyle(font: fontRegular, fontSize: fontSize),
                      children: _buildStyledTextSpans(currentLine, fontRegular,
                          fontBold, fontItalic, fontBoldItalic,
                          defaultFontSize: fontSize),
                    ),
                  ),
                ),
              ),
            );
          }
          // Reset for next line
          currentLine = [];
          // Reset list tracking if not a list
          if (!attrs.containsKey('list')) {
            currentListType = null;
            currentIndentLevel = 0;
          }
        }
      }
    } else if (data is Map) {
      // Handle embeds like images
      if (data.containsKey('image')) {
        // Add image placeholder
        widgets.add(
          pw.Container(
            height: 100,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Center(
              child: pw.Text('[Image]',
                  style: pw.TextStyle(
                      font: fontRegular, fontSize: 10, color: PdfColors.grey)),
            ),
          ),
        );
      } else if (data.containsKey('divider')) {
        // Add divider
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: const pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(width: 1, color: PdfColors.grey300))),
            height: 1,
          ),
        );
      }
    }
  }

  // If there's content in the current line, add it as a paragraph
  if (currentLine.isNotEmpty) {
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.RichText(
          text: pw.TextSpan(
            style: pw.TextStyle(font: fontRegular),
            children: _buildStyledTextSpans(
                currentLine, fontRegular, fontBold, fontItalic, fontBoldItalic),
          ),
        ),
      ),
    );
  }

  return widgets;
}

/// Create styled text spans for the PDF document from formatted text segments
List<pw.TextSpan> _buildStyledTextSpans(
  List<Map<String, dynamic>> segments,
  pw.Font regularFont,
  pw.Font boldFont,
  pw.Font italicFont,
  pw.Font boldItalicFont, {
  double? defaultFontSize,
  pw.Font? defaultFont,
}) {
  return segments.map<pw.TextSpan>((item) {
    final text = item['text']?.toString() ?? '';
    final bold = item['bold'] == true;
    final italic = item['italic'] == true;
    final underline = item['underline'] == true;
    final strike = item['strike'] == true;
    final color =
        item['color'] != null ? _parseColor(item['color'].toString()) : null;
    final segmentFontSize = _mapFontSize(item['size']) ?? defaultFontSize ?? 12;

    // Choose the appropriate font based on formatting
    pw.Font font;
    if (bold && italic) {
      font = boldItalicFont;
    } else if (bold) {
      font = boldFont;
    } else if (italic) {
      font = italicFont;
    } else {
      font = defaultFont ?? regularFont;
    }

    return pw.TextSpan(
      text: text,
      style: pw.TextStyle(
        font: font,
        fontSize: segmentFontSize,
        decoration: underline
            ? pw.TextDecoration.underline
            : strike
                ? pw.TextDecoration.lineThrough
                : null,
        color: color,
      ),
    );
  }).toList();
}

// Helper function to parse color from string
PdfColor _parseColor(String colorStr) {
  try {
    if (colorStr.startsWith('#')) {
      final hex = colorStr.substring(1);
      if (hex.length == 6) {
        final r = int.parse(hex.substring(0, 2), radix: 16) / 255;
        final g = int.parse(hex.substring(2, 4), radix: 16) / 255;
        final b = int.parse(hex.substring(4, 6), radix: 16) / 255;
        return PdfColor(r, g, b);
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error parsing color: $e');
    }
  }
  return PdfColors.black;
}

// Helper function to get header font size
double _getHeaderFontSize(dynamic headerLevel) {
  if (headerLevel is int) {
    switch (headerLevel) {
      case 1:
        return 24;
      case 2:
        return 20;
      case 3:
        return 18;
      case 4:
        return 16;
      case 5:
        return 14;
      case 6:
        return 13;
      default:
        return 12;
    }
  }
  return 12;
}

// Helper function to map Quill alignment strings to PDF TextAlign
pw.TextAlign _getTextAlign(String? align) {
  switch (align) {
    case 'center':
      return pw.TextAlign.center;
    case 'right':
      return pw.TextAlign.right;
    case 'justify':
      return pw.TextAlign.justify;
    default:
      return pw.TextAlign.left;
  }
}

// Helper to map Quill size attribute to font size
double _mapFontSize(dynamic sizeAttr) {
  if (sizeAttr == null) return 12;
  if (sizeAttr is num) return sizeAttr.toDouble();
  if (sizeAttr is String) {
    switch (sizeAttr) {
      case 'small':
        return 10;
      case 'large':
        return 18;
      case 'huge':
        return 22;
      default:
        final parsed = double.tryParse(sizeAttr);
        return parsed ?? 12;
    }
  }
  return 12;
}
