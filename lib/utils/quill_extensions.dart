import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';

// Extension methods to add font family support to QuillEditor
extension QuillEditorExtensions on quill.QuillController {
  // Apply font family to the currently selected text
  void applyFontFamily(String fontFamily) {
    final attribute = quill.Attribute.fromKeyValue('font-family', fontFamily);
    formatSelection(attribute);
  }

  // Get the current font family at the selection point
  String? getCurrentFontFamily() {
    final style = getSelectionStyle();
    return style.attributes['font-family']?.value;
  }
  
  // Apply font size to the currently selected text
  void applyFontSize(double size) {
    final attribute = quill.Attribute.fromKeyValue('size', size.toString());
    formatSelection(attribute);
  }

  // Get the current font size at the selection point
  double? getCurrentFontSize() {
    final style = getSelectionStyle();
    if (style.containsKey('size')) {
      final sizeString = style.attributes['size']?.value;
      if (sizeString != null) {
        return double.tryParse(sizeString);
      }
    }
    return null;
  }
}

// Helper class to style text with custom fonts
class QuillFontUtils {
  // Get a TextStyle with the specified Google Font
  static TextStyle getGoogleFontStyle(String fontFamily, {
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    double? height,
  }) {
    switch (fontFamily) {
      case 'Poppins':
        return GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
      case 'Roboto':
        return GoogleFonts.roboto(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
      case 'Lato':
        return GoogleFonts.lato(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
      case 'Open Sans':
        return GoogleFonts.openSans(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
      case 'Montserrat':
        return GoogleFonts.montserrat(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
      case 'Nunito':
        return GoogleFonts.nunito(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
      case 'Raleway':
        return GoogleFonts.raleway(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
      case 'Ubuntu':
        return GoogleFonts.ubuntu(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
      default:
        return TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
    }
  }
}