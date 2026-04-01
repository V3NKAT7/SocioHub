import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global theme notifier for light/dark mode switching.
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

/// Single global instance — accessible from any file that imports app_theme.dart.
final themeNotifier = ThemeNotifier();

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFFADD984);

  // Dark palette
  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color surfaceDark = Color(0xFF14141E);
  static const Color cardDark = Color(0xFF1A1A27);

  // Light palette
  static const Color backgroundLight = Color(0xFFEBF8FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF1F9FB);

  // Accent Colors
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color purple = Color(0xFFA855F7);
  static const Color violet = Color(0xFF7C5CFC);
  static const Color rose = Color(0xFFF43F5E);
  static const Color orange = Color(0xFFF97316);
  static const Color teal = Color(0xFF14B8A6);
  static const Color pink = Color(0xFFEC4899);

  // ─── Helpers that adapt to dark/light ──────────────────
  static Color bg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? backgroundDark : backgroundLight;

  static Color surface(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color card(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? cardDark : cardLight;

  static Color textPrimary(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? Colors.white : const Color(0xFF1A2235);

  static Color textSecondary(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.5)
          : const Color(0xFF64748B);

  static Color border(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFD5E8EB);

  // ─── Dark Theme ────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surfaceDark,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      fontFamily: GoogleFonts.outfit().fontFamily,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundDark,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  // ─── Light Theme ───────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSurface: Color(0xFF1A2235),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      fontFamily: GoogleFonts.outfit().fontFamily,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
