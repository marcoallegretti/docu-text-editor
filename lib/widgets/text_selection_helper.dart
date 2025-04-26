import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Helper class to work with text selection and determine formatting
class TextSelectionHelper {
  /// Get a map of active formats for the current selection
  static Map<String, bool> getActiveFormats(quill.QuillController controller) {
    final style = controller.getSelectionStyle();

    return {
      'bold': style.containsKey(quill.Attribute.bold.key),
      'italic': style.containsKey(quill.Attribute.italic.key),
      'underline': style.containsKey(quill.Attribute.underline.key),
      'strikeThrough': style.containsKey(quill.Attribute.strikeThrough.key),
      'bulletList': style.containsKey(quill.Attribute.ul.key),
      'numberedList': style.containsKey(quill.Attribute.ol.key),
      'heading1': style.containsKey(quill.Attribute.h1.key),
      'heading2': style.containsKey(quill.Attribute.h2.key),
      'heading3': style.containsKey(quill.Attribute.h3.key),
      'hasTextColor': style.containsKey('color'),
      'hasBackgroundColor': style.containsKey('background'),
    };
  }

  /// Get the text color from the current selection, if any
  static Color? getTextColor(quill.QuillController controller) {
    final style = controller.getSelectionStyle();
    if (style.containsKey('color')) {
      final colorHex = style.attributes['color']?.value;
      if (colorHex != null && colorHex is String && colorHex.startsWith('#')) {
        try {
          return _hexToColor(colorHex);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  /// Get the background color from the current selection, if any
  static Color? getBackgroundColor(quill.QuillController controller) {
    final style = controller.getSelectionStyle();
    if (style.containsKey('background')) {
      final colorHex = style.attributes['background']?.value;
      if (colorHex != null && colorHex is String && colorHex.startsWith('#')) {
        try {
          return _hexToColor(colorHex);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  /// Convert a hex string to Color
  static Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Check if there is any text selected
  static bool hasTextSelected(quill.QuillController controller) {
    return controller.selection.baseOffset != controller.selection.extentOffset;
  }

  /// Select all text in the document
  static void selectAllText(quill.QuillController controller) {
    final documentLength = controller.document.length;
    controller.updateSelection(
      TextSelection(baseOffset: 0, extentOffset: documentLength),
      quill.ChangeSource.local,
    );
  }

  /// Get the current font family from the selection, if any
  static String? getFontFamily(quill.QuillController controller) {
    final style = controller.getSelectionStyle();
    return style.attributes['font']?.value as String?;
  }

  /// Get the current font size from the selection, if any
  static double? getFontSize(quill.QuillController controller) {
    final style = controller.getSelectionStyle();
    final sizeStr = style.attributes['size']?.value;
    if (sizeStr != null && sizeStr is String) {
      try {
        return double.parse(sizeStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Get a human-readable size name from a size value
  static String getFontSizeName(double? size) {
    if (size == null) return 'Normal';

    if (size <= 0.8) {
      return 'Small';
    } else if (size <= 1.0) {
      return 'Normal';
    } else if (size <= 1.5) {
      return 'Large';
    } else if (size <= 2.0) {
      return 'X-Large';
    } else {
      return 'XX-Large';
    }
  }

  /// Get active alignment from the selection
  static String? getAlignment(quill.QuillController controller) {
    final style = controller.getSelectionStyle();

    if (style.containsKey(quill.Attribute.leftAlignment.key)) {
      return 'left';
    } else if (style.containsKey(quill.Attribute.centerAlignment.key)) {
      return 'center';
    } else if (style.containsKey(quill.Attribute.rightAlignment.key)) {
      return 'right';
    } else if (style.containsKey(quill.Attribute.justifyAlignment.key)) {
      return 'justify';
    }

    return null;
  }
}
