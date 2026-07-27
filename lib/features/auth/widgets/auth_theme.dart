import 'package:flutter/material.dart';
import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/core/theme/app_typography.dart';

/// Auth-specific theme aligned with app design system.
class AuthTheme {
  // Surfaces
  static Color get background => AppColors.background;
  static Color get cardBackground => AppColors.white;

  // Brand
  static Color get accent => AppColors.primary;
  static Color get pink => AppColors.primary;
  static List<Color> get gradientColors => AppColors.purpleGradientColors;

  // Text
  static Color get textPrimary => AppColors.textPrimary;
  static Color get textSecondary => AppColors.textSecondary;
  static Color get textGrey => AppColors.textDisabled;

  // Button / input (use design radius where applicable)
  static const double buttonHeight = 56.0;
  static const double buttonBorderRadius = 14.0;
  static const double inputBorderRadius = 14.0;
  static const double inputBorderWidth = 1.0;

  // Typography – delegate to design system
  static TextStyle get headingLarge => AppTypography.headline;
  static TextStyle get headingMedium => AppTypography.title;
  static TextStyle get subtitle => AppTypography.subtitle;
  static TextStyle get bodyText => AppTypography.body;
  static TextStyle get buttonText => AppTypography.button.copyWith(color: AppColors.white);
  static TextStyle get linkText => AppTypography.body.copyWith(
    fontWeight: FontWeight.w600,
    color: accent,
    fontSize: 14,
  );
  static TextStyle get hintText => AppTypography.bodySmall;
}
