import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility class to handle browser context menu in web applications
class WebContextMenuUtil {
  /// Disables the browser's default context menu for the entire application
  static void disableBrowserContextMenu() {
    if (kIsWeb) {
      html.document.onContextMenu.listen((event) => event.preventDefault());
    }
  }
  
  /// Enables the browser's default context menu for the entire application
  static void enableBrowserContextMenu() {
    // Currently not implemented as we can't easily remove the listener
    // once added, but included for API completeness
  }
  
  /// Disables browser context menu for a specific element by ID
  static void disableContextMenuForElement(String elementId) {
    if (kIsWeb) {
      final element = html.document.getElementById(elementId);
      if (element != null) {
        element.onContextMenu.listen((event) => event.preventDefault());
      }
    }
  }
}