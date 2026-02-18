import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class AppTheme {
  // Gemini-inspired neutral palette
  static const _lightBg = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFF0F4F9); // User bubble / Input bg
  static const _darkBg = Color(0xFF131314);
  static const _darkSurface = Color(0xFF1E1F20);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4285F4), // Google Blue-ish
        surface: _lightBg,
        surfaceContainerHighest: _lightSurface,
        onSurface: const Color(0xFF1F1F1F),
        outline: const Color(0xFFE3E3E3),
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: const Color(0xFF1F1F1F),
        displayColor: const Color(0xFF1F1F1F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF444746)),
        titleTextStyle: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Outfit'),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28), // Pill shape
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFE3E3E3), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0, // Gemini is flat
        color: _lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE3E3E3)),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF444746)),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFA8C7FA),
        surface: _darkBg,
        surfaceContainerHighest: _darkSurface,
        onSurface: const Color(0xFFE3E3E3),
        outline: const Color(0xFF444746),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: const Color(0xFFE3E3E3),
        displayColor: const Color(0xFFE3E3E3),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFC4C7C5)),
        titleTextStyle: TextStyle(
            color: Color(0xFFE3E3E3),
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Outfit'),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFF444746), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF444746)),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFC4C7C5)),
    );
  }
}
