import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Discount Buddy – Clean, Modern, Premium Design System
class NeoTasteColors {
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
        backgroundColor: NeoTasteColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      colorScheme: const ColorScheme.light(
        primary: NeoTasteColors.primaryBlue,
        secondary: NeoTasteColors.primaryBlue,
        surface: NeoTasteColors.white,
        error: NeoTasteColors.error,
        onPrimary: NeoTasteColors.white,
        onSecondary: NeoTasteColors.white,
        onSurface: NeoTasteColors.textPrimary,
        onError: NeoTasteColors.white,
      ),
      scaffoldBackgroundColor: NeoTasteColors.background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: NeoTasteColors.background,
        foregroundColor: NeoTasteColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: NeoTasteColors.textPrimary,
          fontSize: 24, // Clear hierarchy
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardColor: NeoTasteColors.white,
      cardTheme: CardThemeData(
        elevation: 0,
        color: NeoTasteColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        shadowColor: NeoTasteColors.textPrimary.withValues(
          alpha: 0.04,
        ), // Minimal shadow
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: NeoTasteColors.white,
        selectedItemColor: NeoTasteColors.primaryBlue,
        unselectedItemColor: NeoTasteColors.textDisabled,
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
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: NeoTasteColors.textPrimary,
          height: 1.1,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: NeoTasteColors.textPrimary,
          height: 1.1,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: NeoTasteColors.textPrimary,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: NeoTasteColors.textPrimary,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: NeoTasteColors.textPrimary,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: NeoTasteColors.textPrimary,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: NeoTasteColors.textPrimary,
          height: 1.3,
        ),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: NeoTasteColors.textPrimary,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: NeoTasteColors.textPrimary,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          color: NeoTasteColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          color: NeoTasteColors.textPrimary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          color: NeoTasteColors.textSecondary,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: NeoTasteColors.textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: NeoTasteColors.textPrimary,
        ),
        labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: NeoTasteColors.textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NeoTasteColors.primaryBlue,
          foregroundColor: NeoTasteColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NeoTasteColors.textPrimary,
          side: BorderSide(
            color: NeoTasteColors.textDisabled.withValues(alpha: 0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: -0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NeoTasteColors.primaryBlue,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeoTasteColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: NeoTasteColors.textDisabled.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: NeoTasteColors.textDisabled.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: NeoTasteColors.primaryBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NeoTasteColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NeoTasteColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: NeoTasteColors.textDisabled,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.inter(
          color: NeoTasteColors.textSecondary,
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
