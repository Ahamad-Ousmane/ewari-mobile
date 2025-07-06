// core/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('is_dark_theme') ?? false;
      state = isDark ? ThemeMode.dark : ThemeMode.light;
      print('🎨 Thème chargé: ${isDark ? 'Sombre' : 'Clair'}');
    } catch (e) {
      print('❌ Erreur chargement thème: $e');
      state = ThemeMode.light; // Fallback
    }
  }

  Future<void> toggleTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      await prefs.setBool('is_dark_theme', newMode == ThemeMode.dark);
      state = newMode;
      print('🎨 Thème changé vers: ${newMode == ThemeMode.dark ? 'Sombre' : 'Clair'}');
    } catch (e) {
      print('❌ Erreur sauvegarde thème: $e');
    }
  }

  bool get isDark => state == ThemeMode.dark;
  bool get isLight => state == ThemeMode.light;
}

// Provider global pour le thème
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});