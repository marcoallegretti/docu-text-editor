import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeService {
  // Update the system UI overlay based on the current theme
  static void updateSystemUIOverlay(bool isDarkTheme) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkTheme ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDarkTheme ? const Color(0xFF1E1E1E) : Colors.white,
      systemNavigationBarIconBrightness: isDarkTheme ? Brightness.light : Brightness.dark,
    ));
  }
}