import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class AppTheme {
  // Gemini-inspired neutral palette - Darkened borders for better visibility
  static const _lightBg = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFF0F4F9); 
  static const _darkBg = Color(0xFF131314);
  static const _darkSurface = Color(0xFF1E1F20);

  // Darkened border colors as requested
  static const _lightOutline = Color(0xFFC7C7C7); // From E3E3E3
  static const _darkOutline = Color(0xFF5F6368);  // From 444746

  static ThemeData getTheme(BuildContext context, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    
    // Responsive scaling factor based on screen width (baseline: 375px mobile)
    // Limits scaling to prevent text from getting too large on tablets or too small on tiny phones
    final double scaleFactor = (screenWidth / 375).clamp(0.85, 1.25);

    // Centralized Typography System: scales naturally while maintaining hierarchy
    TextTheme buildResponsiveTextTheme(TextTheme base) {
      return GoogleFonts.interTextTheme(base).copyWith(
        displayLarge: base.displayLarge?.copyWith(fontSize: (57 * scaleFactor)),
        displayMedium: base.displayMedium?.copyWith(fontSize: (45 * scaleFactor)),
        displaySmall: base.displaySmall?.copyWith(fontSize: (36 * scaleFactor)),
        headlineLarge: base.headlineLarge?.copyWith(fontSize: (32 * scaleFactor)),
        headlineMedium: base.headlineMedium?.copyWith(fontSize: (28 * scaleFactor)),
        headlineSmall: base.headlineSmall?.copyWith(fontSize: (24 * scaleFactor)),
        titleLarge: base.titleLarge?.copyWith(fontSize: (22 * scaleFactor), fontWeight: FontWeight.w500),
        titleMedium: base.titleMedium?.copyWith(fontSize: (16 * scaleFactor), fontWeight: FontWeight.w500),
        titleSmall: base.titleSmall?.copyWith(fontSize: (14 * scaleFactor), fontWeight: FontWeight.w500),
        bodyLarge: base.bodyLarge?.copyWith(fontSize: (16 * scaleFactor), height: 1.5),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: (14 * scaleFactor), height: 1.5),
        bodySmall: base.bodySmall?.copyWith(fontSize: (12 * scaleFactor), height: 1.4),
        labelLarge: base.labelLarge?.copyWith(fontSize: (14 * scaleFactor), fontWeight: FontWeight.w500),
        labelMedium: base.labelMedium?.copyWith(fontSize: (12 * scaleFactor), fontWeight: FontWeight.w500),
        labelSmall: base.labelSmall?.copyWith(fontSize: (11 * scaleFactor), fontWeight: FontWeight.w500),
      ).apply(
        bodyColor: isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
        displayColor: isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
      );
    }

    final themeData = isDark ? ThemeData.dark() : ThemeData.light();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4285F4),
      surface: isDark ? _darkBg : _lightBg,
      surfaceContainerHighest: isDark ? _darkSurface : _lightSurface,
      onSurface: isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
      outline: isDark ? _darkOutline : _lightOutline,
      outlineVariant: isDark ? _darkOutline.withOpacity(0.5) : _lightOutline.withOpacity(0.5),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? _darkBg : _lightBg,
      colorScheme: colorScheme,
      textTheme: buildResponsiveTextTheme(themeData.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? _darkBg : _lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: isDark ? const Color(0xFFC4C7C5) : const Color(0xFF444746)),
        titleTextStyle: GoogleFonts.inter(
          color: isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
          fontSize: 18 * scaleFactor,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _darkSurface : _lightSurface,
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
          borderSide: BorderSide(color: colorScheme.outline, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? _darkSurface : _lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      iconTheme: IconThemeData(color: isDark ? const Color(0xFFC4C7C5) : const Color(0xFF444746)),
    );
  }

  // Backwards compatibility for existing references if any, though it's better to update usage
  static ThemeData get lightTheme => throw UnimplementedError('Use getTheme(context, Brightness.light) instead');
  static ThemeData get darkTheme => throw UnimplementedError('Use getTheme(context, Brightness.dark) instead');
}
