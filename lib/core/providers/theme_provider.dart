import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'spendly_theme_mode';

/// Controls the app-wide theme mode. Defaults to system.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _restoreThemeMode();
  }

  Future<void> _restoreThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    if (value == 'light') {
      state = ThemeMode.light;
      return;
    }
    if (value == 'dark') {
      state = ThemeMode.dark;
      return;
    }
    state = ThemeMode.system;
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString(_themeModeKey, 'light');
      return;
    }
    if (mode == ThemeMode.dark) {
      await prefs.setString(_themeModeKey, 'dark');
      return;
    }
    await prefs.remove(_themeModeKey);
  }

  bool get isDark => state == ThemeMode.dark;
}
