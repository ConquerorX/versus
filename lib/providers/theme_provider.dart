import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════
// Tema modu (Sistem / Açık / Koyu)
// ═══════════════════════════════════════════════
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.system;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt('themeMode') ?? 0;
    state = _fromInt(value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _toInt(mode));
  }

  int _toInt(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 0;
      case ThemeMode.light: return 1;
      case ThemeMode.dark: return 2;
    }
  }

  ThemeMode _fromInt(int value) {
    switch (value) {
      case 1: return ThemeMode.light;
      case 2: return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}

// ═══════════════════════════════════════════════
// Accent renk paleti
// ═══════════════════════════════════════════════

/// Kullanılabilir renk paletleri
enum AccentPalette {
  copper('Bakır', Color(0xFFC8956C), Color(0xFFE8B88A), Color(0xFFAA7B56), Color(0xFF5B8A72)), // Bakıra zıt Yeşil
  ocean('Okyanus', Color(0xFF4A90D9), Color(0xFF74B9FF), Color(0xFF2E6CB8), Color(0xFFE17055)), // Maviye zıt Turuncu
  emerald('Zümrüt', Color(0xFF2ECC71), Color(0xFF55EFC4), Color(0xFF27AE60), Color(0xFF9B59B6)), // Yeşile zıt Mor
  lavender('Lavanta', Color(0xFF9B59B6), Color(0xFFBE90D4), Color(0xFF8E44AD), Color(0xFFF1C40F)), // Mora zıt Sarı
  rose('Gül', Color(0xFFE84393), Color(0xFFFD79A8), Color(0xFFD63384), Color(0xFF00CEC9)), // Pembeye zıt Camgöbeği
  sunset('Gün Batımı', Color(0xFFE17055), Color(0xFFFAB1A0), Color(0xFFD35400), Color(0xFF0984E3)); // Turuncuya zıt Koyu Mavi

  final String label;
  final Color primary;
  final Color light;
  final Color dark;
  final Color tertiary; // 2. Öğe (Item 2) için zıt renk

  const AccentPalette(this.label, this.primary, this.light, this.dark, this.tertiary);
}

final accentColorProvider = NotifierProvider<AccentColorNotifier, AccentPalette>(
  AccentColorNotifier.new,
);

class AccentColorNotifier extends Notifier<AccentPalette> {
  @override
  AccentPalette build() {
    _load();
    return AccentPalette.copper;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('accentPalette') ?? 0;
    if (idx >= 0 && idx < AccentPalette.values.length) {
      state = AccentPalette.values[idx];
    }
  }

  Future<void> setPalette(AccentPalette palette) async {
    state = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accentPalette', palette.index);
  }
}
