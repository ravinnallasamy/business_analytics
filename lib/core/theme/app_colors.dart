import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Backgrounds
  static const Color primaryBackground = Color(0xFFFDFBF7); // Soft cream / off-white
  static const Color sidebarBackground = Color(0xFF1A1A1A); // Dark charcoal / near-black
  
  // Accents
  static const Color accentGreen = Color(0xFF2D6A4F); // Primary icons, active indicators, action buttons
  static const Color accentGold = Color(0xFFD4AF37); // Table headers, highlight rows, emphasis
  
  // Neutrals / Borders
  static const Color borderGray = Color(0xFFE0E0E0); // Subtle gray for cards/tables
  static const Color textPrimary = Color(0xFF1A1A1A); // Near-black for main text
  static const Color textSecondary = Color(0xFF6C757D); // Neutral gray for secondary text
  static const Color textOnDark = Color(0xFFFDFBF7); // Cream/white for text on dark backgrounds
  
  // Functional
  static const Color inactive = Color(0xFFADB5BD);
  static const Color cardBackground = Colors.white;
  static const Color tableHeaderBg = Color(0xFFD4AF37);
  static const Color selectionOverlay = Color(0x1A2D6A4F); // 10% opacity accent green
}
