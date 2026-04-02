import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Keys ────────────────────────────────────────────────────────────────────
const _themeModeKey = 'spendly_theme_mode';
const _currencyKey = 'spendly_currency';

// ─── Currency Enum ───────────────────────────────────────────────────────────
enum AppCurrency {
  inr,
  usd,
  eur;

  String get symbol {
    switch (this) {
      case AppCurrency.inr:
        return '₹';
      case AppCurrency.usd:
        return '\$';
      case AppCurrency.eur:
        return '€';
    }
  }

  String get code {
    switch (this) {
      case AppCurrency.inr:
        return 'INR';
      case AppCurrency.usd:
        return 'USD';
      case AppCurrency.eur:
        return 'EUR';
    }
  }

  String get label {
    switch (this) {
      case AppCurrency.inr:
        return '₹ INR';
      case AppCurrency.usd:
        return '\$ USD';
      case AppCurrency.eur:
        return '€ EUR';
    }
  }
}

// ─── Theme Mode Provider ─────────────────────────────────────────────────────
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    if (value == 'light') {
      state = ThemeMode.light;
    } else if (value == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_themeModeKey, 'light');
      case ThemeMode.dark:
        await prefs.setString(_themeModeKey, 'dark');
      case ThemeMode.system:
        await prefs.remove(_themeModeKey);
    }
  }
}

// ─── Currency Provider ───────────────────────────────────────────────────────
final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, AppCurrency>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<AppCurrency> {
  CurrencyNotifier() : super(AppCurrency.inr) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_currencyKey);
    if (value != null) {
      state = AppCurrency.values.firstWhere(
        (c) => c.code == value,
        orElse: () => AppCurrency.inr,
      );
    }
  }

  Future<void> setCurrency(AppCurrency currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.code);
  }
}
