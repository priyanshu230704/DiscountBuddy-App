import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';

/// Discount Buddy – Clean, Modern, Premium Design System
class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  /// Solid primary action color for buttons only
  static const Color primaryBlue = Color(0xFF2563EB);

  // Functional colors
  static const Color discount = Color(0xFFFF7A00); // badge / discount labels
  static const Color success = Color(0xFF16A34A); // confirmed / redeemed
  static const Color error = Color(0xFFEF4444);

  // Surfaces
  static const Color background = Color(0xFFF8F9FC); // neutral light-grey
  static const Color white = Color(0xFFFFFFFF); // card background

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);

  // Backward-compat aliases
  static const Color primary = primaryBlue;
  static const Color primaryLight = primaryBlue;
  static const Color accent = primaryBlue;
  static const Color green = success;
  static const Color pink =
      primaryBlue; // Remove pink accent, use purple consistently

  // No gradients in new design, returning solid purple fallback for legacy
  static const List<Color> primaryGradientColors = [primaryBlue, primaryBlue];

  static Gradient get primaryGradient =>
      const LinearGradient(colors: primaryGradientColors);
}

class ThemeProvider extends ChangeNotifier {
  final bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryBlue,
        surface: AppColors.white,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontFamily: AppFonts.titleFont,
          color: AppColors.textPrimary,
          fontSize: 24, // Clear hierarchy
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardColor: AppColors.white,
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        shadowColor: AppColors.textPrimary.withValues(
          alpha: 0.04,
        ), // Minimal shadow
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textDisabled,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: const TextTheme().copyWith(
        displayLarge: const TextStyle(
          fontFamily: AppFonts.titleFont,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          height: 1.1,
          letterSpacing: -1,
        ),
        displayMedium: const TextStyle(
          fontFamily: AppFonts.titleFont,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          height: 1.1,
          letterSpacing: -0.5,
        ),
        displaySmall: const TextStyle(
          fontFamily: AppFonts.titleFont,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        headlineLarge: const TextStyle(
          fontFamily: AppFonts.titleFont,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontFamily: AppFonts.titleFont,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        headlineSmall: const TextStyle(
          fontFamily: AppFonts.titleFont,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        titleLarge: const TextStyle(
          fontFamily: AppFonts.titleFont,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        titleMedium: const TextStyle(
          fontFamily: AppFonts.titleFont,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        titleSmall: const TextStyle(
          fontFamily: AppFonts.titleFont,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        bodyLarge: const TextStyle(
          fontFamily: AppFonts.bodyFont,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontFamily: AppFonts.bodyFont,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodySmall: const TextStyle(
          fontFamily: AppFonts.bodyFont,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        labelLarge: const TextStyle(
          fontFamily: AppFonts.bodyFont,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: const TextStyle(
          fontFamily: AppFonts.bodyFont,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelSmall: const TextStyle(
          fontFamily: AppFonts.bodyFont,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: AppFonts.buttonFont,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(
            color: AppColors.textDisabled.withValues(alpha: 0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: AppFonts.buttonFont,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: -0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: const TextStyle(
            fontFamily: AppFonts.buttonFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.textDisabled.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.textDisabled.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(
          fontFamily: AppFonts.inputFont,
          color: AppColors.textDisabled,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          fontFamily: AppFonts.inputFont,
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  ThemeData get darkTheme => lightTheme;
  ThemeData get currentTheme => lightTheme;

  void toggleTheme() {}
  void setTheme(bool isDark) {}
}
