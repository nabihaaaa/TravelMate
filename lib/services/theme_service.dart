import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );

  static const String _themeKey = 'dark_mode';

  // Load the user's saved theme preference.
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool(_themeKey) ?? false;

    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // Save the user's selected theme.
  static Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_themeKey, isDark);

    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}
