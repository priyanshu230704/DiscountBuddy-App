import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';

/// NeoTaste Auth Theme - Centralized styling for authentication screens
class AuthTheme {
  // Colors - Using NeoTaste light theme colors
  static const Color background = NeoTasteColors.background; // Light Grey #F6F6F6
  static const Color accent = NeoTasteColors.accent; // NeoTaste Yellow
  static const Color textPrimary = NeoTasteColors.textPrimary; // Black
  static const Color textSecondary = NeoTasteColors.textSecondary; // Grey
  static const Color textGrey = NeoTasteColors.textDisabled; // Light Grey
  
  // Button Styles
  static const double buttonHeight = 56.0;
  static const double buttonBorderRadius = 28.0; // Pill shape
  
  // Input Styles
  static const double inputBorderRadius = 12.0;
  static const double inputBorderWidth = 1.0;
  
  // Typography
  static TextStyle headingLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static TextStyle headingMedium = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static TextStyle subtitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );
  
  static TextStyle bodyText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );
  
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textPrimary, // Black text on yellow button
  );
  
  static TextStyle linkText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: accent,
  );
  
  static TextStyle hintText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textGrey,
  );
}
