import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoSaveProvider extends ChangeNotifier {
  static const String _autoSavePreferenceKey = 'is_auto_save_enabled';
  bool _isAutoSaveEnabled = true;
  bool get isAutoSaveEnabled => _isAutoSaveEnabled;

  AutoSaveProvider() {
    _loadAutoSavePreference();
  }

  Future<void> _loadAutoSavePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAutoSave = prefs.getBool(_autoSavePreferenceKey);
    if (savedAutoSave != null) {
      _isAutoSaveEnabled = savedAutoSave;
      notifyListeners();
    }
  }

  Future<void> setAutoSaveEnabled(bool value) async {
    if (_isAutoSaveEnabled != value) {
      _isAutoSaveEnabled = value;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoSavePreferenceKey, _isAutoSaveEnabled);
    }
  }
}
