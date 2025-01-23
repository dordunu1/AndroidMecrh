import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifierProvider, ThemeMode>((ref) {
  return ThemeNotifierProvider();
});

class ThemeNotifierProvider extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';
  late SharedPreferences _prefs;

  ThemeNotifierProvider() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs.getString(_key);
    if (savedTheme != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_key, mode.toString());
    state = mode;
  }

  Future<void> toggleTheme() async {
    final isDark = state == ThemeMode.dark;
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  bool get isDarkMode => state == ThemeMode.dark;
} 