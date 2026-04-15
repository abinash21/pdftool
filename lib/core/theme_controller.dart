import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _hapticEnabled = false;

  ThemeMode get themeMode => _themeMode;
  bool get hapticEnabled => _hapticEnabled;

  ThemeController() {
    _loadPrefs();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    _saveTheme(mode);

    notifyListeners();
  }

  void setHaptic(bool value) {
    _hapticEnabled = value;
    _saveHaptic(value);

    if (value) {
      HapticFeedback.mediumImpact();
    }

    notifyListeners();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt("themeMode");
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    _hapticEnabled = prefs.getBool("hapticEnabled") ?? false;

    notifyListeners();
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("themeMode", mode.index);
  }

  Future<void> _saveHaptic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("hapticEnabled", value);
  }
}
