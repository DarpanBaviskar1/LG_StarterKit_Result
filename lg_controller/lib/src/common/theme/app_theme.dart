
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final darkTheme = _buildTheme(
    brightness: Brightness.dark,
    scaffold: const Color(0xFF121212),
    surface: const Color(0xFF1E1E1E),
    inputFill: const Color(0xFF2C2C2C),
    textTheme: ThemeData.dark().textTheme,
  );

  static final lightTheme = _buildTheme(
    brightness: Brightness.light,
    scaffold: const Color(0xFFF7F7FA),
    surface: Colors.white,
    inputFill: const Color(0xFFEFF1F5),
    textTheme: ThemeData.light().textTheme,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color inputFill,
    required TextTheme textTheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
        brightness: brightness,
        surface: surface,
        background: scaffold,
      ),
      scaffoldBackgroundColor: scaffold,
      textTheme: GoogleFonts.interTextTheme(textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: brightness == Brightness.dark
              ? Colors.white
              : Colors.white,
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
