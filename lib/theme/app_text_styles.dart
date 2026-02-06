import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // We'll dynamically generate styles based on brightness (light/dark)
  // or just return the base TExtStyle and let Theme handle color.
  // Requirement says: "All widgets must consume Theme.of(context)"
  // So we should define `TextTheme` here or Helper methods.
  // The structure suggests a class holding static styles or a method to get TextTheme.

  static TextTheme getTextTheme(bool isDark) {
    final Color primaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final Color secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return GoogleFonts.lexendTextTheme().copyWith(
      // Screen Title (Headline Small/Medium in Material 3)
      headlineSmall: GoogleFonts.lexend(
        fontSize: 24,
        fontWeight: FontWeight.w600, // Semibold
        color: primaryColor,
      ),

      // Section Header (Title Large)
      titleLarge: GoogleFonts.lexend(
        fontSize: 18,
        fontWeight: FontWeight.w500, // Medium
        color: primaryColor,
      ),

      // Card Title / Discount / Price (Title Medium)
      titleMedium: GoogleFonts.lexend(
        fontSize: 16,
        fontWeight: FontWeight.w500, // Medium
        color: primaryColor,
      ),

      // Body (Body Medium)
      bodyMedium: GoogleFonts.lexend(
        fontSize: 14,
        fontWeight: FontWeight.w400, // Regular
        color: primaryColor,
      ),

      // Caption (Body Small or Label Small)
      bodySmall: GoogleFonts.lexend(
        fontSize: 12,
        fontWeight: FontWeight.w400, // Regular
        color: secondaryColor,
      ),

      // Button Text (Label Large)
      labelLarge: GoogleFonts.lexend(
        fontSize: 16,
        fontWeight: FontWeight.w600, // Semibold for buttons usually
        color: primaryColor,
      ),
    );
  }
}
