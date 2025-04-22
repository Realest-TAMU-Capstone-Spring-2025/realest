// File: test/lib_tests/theme_provider_tests.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:realest/theme_provider.dart';

void main() {
  group('ThemeProvider.themeMode getter', () {
    test('☀️ default is ThemeMode.system', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, equals(ThemeMode.system));
    });

    test('🌧 default is neither light nor dark', () {
      final provider = ThemeProvider();
      final mode = provider.themeMode;
      expect(mode == ThemeMode.light || mode == ThemeMode.dark, isFalse);
    });
  });

  group('ThemeProvider.toggleTheme()', () {
    test('☀️ toggles from system → light', () {
      final provider = ThemeProvider();
      provider.toggleTheme();
      expect(provider.themeMode, equals(ThemeMode.light));
    });

    test('🌧 toggles again from light → dark', () {
      final provider = ThemeProvider();
      provider.toggleTheme(); // system → light
      provider.toggleTheme(); // light  → dark
      expect(provider.themeMode, equals(ThemeMode.dark));
    });
  });
}
