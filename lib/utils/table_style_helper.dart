import 'package:flutter/material.dart';
import '../theme.dart';

/// A helper class to style tables based on the current theme
class TableStyleHelper {
  /// Apply proper styling to a markdown table based on the current theme
  static String applyTableStyling(String markdownTable, bool isDarkMode) {
    if (!isDarkMode) {
      // In light mode, use default markdown styling
      return markdownTable;
    }
    
    // In dark mode, wrap the table in a special HTML div with styling
    // This is a bit of a hack but works for simple rendering
    return '''
<div style="color: ${_colorToHex(Colors.white)}; background-color: ${_colorToHex(AppTheme.darkPaperColor)}">
$markdownTable
</div>
''';
  }
  
  /// Convert a color to hex string for HTML styling
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }
  
  /// Create custom table styling for the current theme
  static TableStyle getThemedTableStyle(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return TableStyle(
      borderColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
      headerBackgroundColor: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
      cellBackgroundColor: isDarkMode ? AppTheme.darkPaperColor : Colors.white,
      textColor: isDarkMode ? Colors.white : Colors.black87,
      headerTextColor: isDarkMode ? Colors.white : Colors.black,
    );
  }
  
  /// Get a visually distinct background color for selected text
  static Color getSelectionBackgroundColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode 
        ? AppTheme.darkPrimaryColor.withOpacity(0.3)
        : AppTheme.primaryColor.withOpacity(0.2);
  }
  
  /// Get appropriate text color for the current theme
  static Color getAppropriateTextColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.white : Colors.black87;
  }
}

/// A simple class to hold table styling properties
class TableStyle {
  final Color borderColor;
  final Color headerBackgroundColor;
  final Color cellBackgroundColor;
  final Color textColor;
  final Color headerTextColor;
  
  const TableStyle({
    required this.borderColor,
    required this.headerBackgroundColor,
    required this.cellBackgroundColor,
    required this.textColor,
    required this.headerTextColor,
  });
}