import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'is_dark_theme';
  bool _isDarkTheme = false;
  bool get isDarkTheme => _isDarkTheme;

  ThemeProvider() {
    _loadThemePreference();
  }

  // Load saved theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIsDarkTheme = prefs.getBool(_themePreferenceKey);
    
    if (savedIsDarkTheme != null) {
      _isDarkTheme = savedIsDarkTheme;
      ThemeService.updateSystemUIOverlay(_isDarkTheme);
      notifyListeners();
    }
  }

  // Toggle between light and dark theme
  Future<void> toggleTheme() async {
    _isDarkTheme = !_isDarkTheme;
    ThemeService.updateSystemUIOverlay(_isDarkTheme);
    notifyListeners();
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, _isDarkTheme);
  }

  // Set a specific theme
  Future<void> setDarkTheme(bool value) async {
    if (_isDarkTheme != value) {
      _isDarkTheme = value;
      ThemeService.updateSystemUIOverlay(_isDarkTheme);
      notifyListeners();
      
      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, _isDarkTheme);
    }
  }
}