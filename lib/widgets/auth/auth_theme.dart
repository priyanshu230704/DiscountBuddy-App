import 'package:discount_buddy/theme/app_colors.dart';

import 'package:discount_buddy/theme/app_fonts.dart';
import 'package:flutter/material.dart';

/// Discount Buddy Auth Theme – Modern Purple
class AuthTheme {
  // Surfaces
  static Color background = AppColors.background; // #F8F9FC neutral
  static Color cardBackground = AppColors.white;

  // Brand
  static Color accent = AppColors.primaryPurple; // solid primary action
  static Color pink = AppColors.primaryPurple;
  static const List<Color> gradientColors = [
    AppColors.primaryPurple,
    AppColors.primaryPurple,
  ];

  // Text
  static Color textPrimary = AppColors.textPrimary;
  static Color textSecondary = AppColors.textSecondary;
  static Color textGrey = AppColors.textDisabled;

  // Button Styles
  static const double buttonHeight = 56.0;
  static const double buttonBorderRadius = 14.0;

  // Input Styles
  static const double inputBorderRadius = 14.0;
  static const double inputBorderWidth = 1.0;

  // Typography
  static TextStyle headingLarge = AppFonts.bodyStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -1,
  );

  static TextStyle headingMedium = AppFonts.bodyStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle subtitle = AppFonts.bodyStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle bodyText = AppFonts.bodyStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle buttonText = AppFonts.bodyStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: -0.1,
  );

  static TextStyle linkText = AppFonts.bodyStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: accent, // primaryBlue
  );

  static TextStyle hintText = AppFonts.bodyStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textGrey,
  );
}
