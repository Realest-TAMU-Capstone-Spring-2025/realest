import 'package:flutter/material.dart';

/// Manages the app's theme mode and notifies listeners on changes.
class ThemeProvider with ChangeNotifier {
  /// Current theme mode (light, dark, or system).
  ThemeMode _themeMode = ThemeMode.system;

  /// Gets the current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Toggles between light and dark theme modes.
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}