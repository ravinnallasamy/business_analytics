import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData getTheme(BuildContext context, Brightness brightness) {
    // Note: The palette is designed to be consistent. 
    // Even in "dark mode" system settings, we maintain the dark sidebar / light content 
    // distinction as requested in the visual reference.
    
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double scaleFactor = (screenWidth / 375).clamp(0.85, 1.25);

    TextTheme buildResponsiveTextTheme(TextTheme base) {
      return GoogleFonts.interTextTheme(base).copyWith(
        displayLarge: base.displayLarge?.copyWith(fontSize: (57 * scaleFactor)),
        displayMedium: base.displayMedium?.copyWith(fontSize: (45 * scaleFactor)),
        displaySmall: base.displaySmall?.copyWith(fontSize: (36 * scaleFactor)),
        headlineLarge: base.headlineLarge?.copyWith(fontSize: (32 * scaleFactor)),
        headlineMedium: base.headlineMedium?.copyWith(fontSize: (28 * scaleFactor)),
        headlineSmall: base.headlineSmall?.copyWith(fontSize: (24 * scaleFactor)),
        titleLarge: base.titleLarge?.copyWith(fontSize: (22 * scaleFactor), fontWeight: FontWeight.w600),
        titleMedium: base.titleMedium?.copyWith(fontSize: (16 * scaleFactor), fontWeight: FontWeight.w600),
        titleSmall: base.titleSmall?.copyWith(fontSize: (14 * scaleFactor), fontWeight: FontWeight.w600),
        bodyLarge: base.bodyLarge?.copyWith(fontSize: (16 * scaleFactor), height: 1.5),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: (14 * scaleFactor), height: 1.5),
        bodySmall: base.bodySmall?.copyWith(fontSize: (12 * scaleFactor), height: 1.4),
        labelLarge: base.labelLarge?.copyWith(fontSize: (14 * scaleFactor), fontWeight: FontWeight.w500),
        labelMedium: base.labelMedium?.copyWith(fontSize: (12 * scaleFactor), fontWeight: FontWeight.w500),
        labelSmall: base.labelSmall?.copyWith(fontSize: (11 * scaleFactor), fontWeight: FontWeight.w500),
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      );
    }

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.accentGreen,
      onPrimary: Colors.white,
      secondary: AppColors.accentGold,
      onSecondary: Colors.white,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: AppColors.primaryBackground,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.borderGray.withOpacity(0.5),
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderGray,
      outlineVariant: AppColors.borderGray.withOpacity(0.5),
      shadow: Colors.black.withOpacity(0.05),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      colorScheme: colorScheme,
      textTheme: buildResponsiveTextTheme(ThemeData.light().textTheme),
      
      // Sidebar styling via DrawerTheme
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.sidebarBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.accentGreen),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18 * scaleFactor,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderGray),
        ),
      ),

      // Table styling
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.accentGold),
        headingTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14 * scaleFactor,
        ),
        dataTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 14 * scaleFactor,
        ),
        dividerThickness: 1,
        horizontalMargin: 16,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderGray,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.accentGreen, size: 24),
    );
  }

  // Backwards compatibility
  static ThemeData get lightTheme => throw UnimplementedError('Use getTheme(context, Brightness.light)');
  static ThemeData get darkTheme => throw UnimplementedError('Use getTheme(context, Brightness.dark)');
}

