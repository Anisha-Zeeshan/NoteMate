import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Scheme F: Blush + Gold ────────────────────────────────────
// Primary:    #AD1457 (deep rose/blush)
// Accent:     #FFC107 (gold/amber)
// BG Light:   #FCE4EC (soft pink-white)
// BG Dark:    #1A0A12 (very dark burgundy)
// Card Dark:  #2D0F1C

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance =
  ThemeProvider._internal();
  factory ThemeProvider() => _instance;
  ThemeProvider._internal();

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final prefs =
    await SharedPreferences.getInstance();
    final dark =
        prefs.getBool('dark_mode') ?? false;
    _themeMode =
    dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDark
        ? ThemeMode.light
        : ThemeMode.dark;
    final prefs =
    await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
    notifyListeners();
  }

  // ── Light theme ───────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFFAD1457),
    scaffoldBackgroundColor:
    const Color(0xFFFCE4EC),
    cardColor: Colors.white,
    dividerColor: Colors.grey.shade200,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFAD1457),
      brightness: Brightness.light,
      surface: Colors.white,
      background: const Color(0xFFFCE4EC),
      primary: const Color(0xFFAD1457),
      secondary: const Color(0xFFFFC107),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFAD1457),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFAD1457),
        foregroundColor: Colors.white,
      ),
    ),
    bottomNavigationBarTheme:
    const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFFAD1457),
      unselectedItemColor: Colors.grey,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
    ),
    textTheme: const TextTheme(
      bodyLarge:
      TextStyle(color: Colors.black87),
      bodyMedium:
      TextStyle(color: Colors.black87),
      titleLarge: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(
        color: Colors.black87),
    dialogBackgroundColor: Colors.white,
    bottomSheetTheme:
    const BottomSheetThemeData(
      backgroundColor: Colors.white,
    ),
  );

  // ── Dark theme ────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFAD1457),
    scaffoldBackgroundColor:
    const Color(0xFF1A0A12),
    cardColor: const Color(0xFF2D0F1C),
    dividerColor: Colors.grey.shade800,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFAD1457),
      brightness: Brightness.dark,
      surface: const Color(0xFF2D0F1C),
      background: const Color(0xFF1A0A12),
      primary: const Color(0xFFAD1457),
      secondary: const Color(0xFFFFC107),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D0F1C),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFAD1457),
        foregroundColor: Colors.white,
      ),
    ),
    bottomNavigationBarTheme:
    const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2D0F1C),
      selectedItemColor: Color(0xFFAD1457),
      unselectedItemColor: Colors.grey,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A0A12),
      hintStyle: TextStyle(
          color: Colors.grey.shade500),
      labelStyle:
      const TextStyle(color: Colors.white70),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium:
      TextStyle(color: Colors.white70),
      titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold),
    ),
    iconTheme:
    const IconThemeData(color: Colors.white),
    dialogBackgroundColor:
    const Color(0xFF2D0F1C),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF2D0F1C),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.all(
          Colors.white),
      trackColor:
      MaterialStateProperty.resolveWith(
              (s) =>
          s.contains(
              MaterialState.selected)
              ? const Color(0xFFAD1457)
              : Colors.grey.shade700),
    ),
  );
}