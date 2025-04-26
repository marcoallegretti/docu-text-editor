import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Helper class for configuring and working with Flutter Quill
class QuillDefaults {
  /// Properly format a color for use with Quill
  static String formatColorHex(Color color) {
    // Include the # prefix and remove alpha channel as Quill expects
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  /// Apply text color to the current selection
  static void applyTextColor(quill.QuillController controller, Color color) {
    final hex = formatColorHex(color);
    controller.formatSelection(quill.Attribute.fromKeyValue('color', hex));
    
    // The editor doesn't always update until refocused, so we'll force an update
    final currentSelection = controller.selection;
    controller.updateSelection(
      TextSelection.collapsed(offset: currentSelection.baseOffset),
      quill.ChangeSource.local,
    );
    controller.updateSelection(
      currentSelection,
      quill.ChangeSource.local,
    );
  }
  
  /// Apply background/highlight color to the current selection
  static void applyBackgroundColor(quill.QuillController controller, Color color) {
    final hex = formatColorHex(color);
    controller.formatSelection(quill.Attribute.fromKeyValue('background', hex));
    
    // The editor doesn't always update until refocused, so we'll force an update
    final currentSelection = controller.selection;
    controller.updateSelection(
      TextSelection.collapsed(offset: currentSelection.baseOffset),
      quill.ChangeSource.local,
    );
    controller.updateSelection(
      currentSelection,
      quill.ChangeSource.local,
    );
  }
  
  /// Clear text color from selection
  static void clearTextColor(quill.QuillController controller) {
    controller.formatSelection(quill.Attribute.clone(quill.Attribute.color, null));
  }
  
  /// Clear background color from selection
  static void clearBackgroundColor(quill.QuillController controller) {
    controller.formatSelection(quill.Attribute.clone(quill.Attribute.background, null));
  }
  
  /// Apply heading style to the current selection (h1, h2, h3 or null for normal)
  static void applyHeading(quill.QuillController controller, quill.Attribute? heading) {
    // Clear any existing heading attributes first
    controller.formatSelection(quill.Attribute.clone(quill.Attribute.h1, null));
    controller.formatSelection(quill.Attribute.clone(quill.Attribute.h2, null));
    controller.formatSelection(quill.Attribute.clone(quill.Attribute.h3, null));
    
    // Apply the new heading if one was specified
    if (heading != null) {
      controller.formatSelection(heading);
    }
  }
  
  /// Get the active heading level from the current selection (null if no heading)
  static quill.Attribute? getActiveHeading(quill.QuillController controller) {
    final style = controller.getSelectionStyle();
    
    if (style.containsKey(quill.Attribute.h1.key)) {
      return quill.Attribute.h1;
    } else if (style.containsKey(quill.Attribute.h2.key)) {
      return quill.Attribute.h2;
    } else if (style.containsKey(quill.Attribute.h3.key)) {
      return quill.Attribute.h3;
    }
    
    return null;
  }
  
  /// Default configuration for Quill Editor
  static Map<String, dynamic> defaultEditorConfig() {
    return {
      'placeholder': 'Start typing...',
      'readOnly': false,
      'autoFocus': false,
    };
  }
}