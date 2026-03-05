import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData getTheme(BuildContext context, Brightness brightness) {
    // Note: The palette is designed to be consistent. 
    // Even in "dark mode" system settings, we maintain the dark sidebar / light content 
    // distinction as requested in the visual reference.
    
    TextTheme buildTextTheme(Brightness brightness) {
      final Color textColor = brightness == Brightness.light ? AppColors.textPrimary : Colors.white;
      final Color secondaryColor = brightness == Brightness.light ? AppColors.textSecondary : Colors.white70;

      return const TextTheme(
        // Metric numbers (22-26 Bold)
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        // App titles (20 SemiBold)
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Section headings (18 SemiBold)
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Body text (15 Regular)
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        // Table text / Labels (14 Medium for headers, but default bodyMedium for rows)
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        // Secondary text (13 Regular)
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        // UI Controls / Labels (14 Medium)
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      );
    }

    final colorScheme = ColorScheme(
      brightness: brightness,
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
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.primaryBackground,
      colorScheme: colorScheme,
      textTheme: buildTextTheme(brightness),
      
      // Sidebar styling via DrawerTheme
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.sidebarBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.accentGreen),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textPrimary,
          fontSize: 20,
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
      dataTableTheme: const DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(AppColors.accentGold),
        headingTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontWeight: FontWeight.w500, // Medium for table headers
          fontSize: 14,
        ),
        dataTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400, // Regular for body
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
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500, // Medium for UI controls
            fontSize: 14,
          ),
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.accentGreen, size: 24),
    );
  }

  // Backwards compatibility
  static ThemeData get lightTheme => throw UnimplementedError('Use getTheme(context, Brightness.light)');
  static ThemeData get darkTheme => throw UnimplementedError('Use getTheme(context, Brightness.dark)');
}

