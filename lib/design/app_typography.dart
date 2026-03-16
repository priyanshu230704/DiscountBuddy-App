import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import 'app_colors.dart';

/// Semantic typography scale reused across screens and components.
class AppTypography {
  // Display / page headers
  static TextStyle headline = TextStyle(
    fontFamily: AppFonts.headingFont,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.1,
    color: AppColors.textDarkest,
  );

  static TextStyle title = TextStyle(
    fontFamily: AppFonts.titleFont,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
    color: AppColors.textDarkest,
  );

  static TextStyle subtitle = TextStyle(
    fontFamily: AppFonts.bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle body = TextStyle(
    fontFamily: AppFonts.bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static TextStyle caption = TextStyle(
    fontFamily: AppFonts.bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textDisabled,
  );

  static TextStyle button = TextStyle(
    fontFamily: AppFonts.buttonFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.white,
  );
}

