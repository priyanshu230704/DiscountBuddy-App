import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// NeoTaste Design System Colors
class NeoTasteColors {
  static const Color primary = Color(0xFF000000); // Black
  static const Color green = Color(0xFF00FF00); // Green
  static const Color accent = Color(0xFFFFC83D); // Warm Yellow
  static const Color background = Color(0xFFF6F6F6); // Light Grey
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color white = Color(0xFFFFFFFF);
}

class ThemeProvider extends ChangeNotifier {
  // NeoTaste uses light theme only
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: NeoTasteColors.primary,
        secondary: NeoTasteColors.accent,
        surface: NeoTasteColors.white,
        background: NeoTasteColors.background,
        error: Colors.red,
        onPrimary: NeoTasteColors.white,
        onSecondary: NeoTasteColors.primary,
        onSurface: NeoTasteColors.textPrimary,
        onBackground: NeoTasteColors.textPrimary,
        onError: NeoTasteColors.white,
      ),
      scaffoldBackgroundColor: NeoTasteColors.background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: NeoTasteColors.white,
        foregroundColor: NeoTasteColors.textPrimary,
        titleTextStyle: GoogleFonts.inter(
          color: NeoTasteColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardColor: NeoTasteColors.white,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogBackgroundColor: NeoTasteColors.white,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: NeoTasteColors.white,
        selectedItemColor: NeoTasteColors.accent,
        unselectedItemColor: NeoTasteColors.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: NeoTasteColors.textPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: NeoTasteColors.textPrimary,
        ),
        displaySmall: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: NeoTasteColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: NeoTasteColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: NeoTasteColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: NeoTasteColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: NeoTasteColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: NeoTasteColors.textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: NeoTasteColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          color: NeoTasteColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          color: NeoTasteColors.textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          color: NeoTasteColors.textSecondary,
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
          fontWeight: FontWeight.normal,
          color: NeoTasteColors.textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NeoTasteColors.accent,
          foregroundColor: NeoTasteColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NeoTasteColors.primary,
          side: const BorderSide(color: NeoTasteColors.accent, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  ThemeData get darkTheme => lightTheme; // NeoTaste uses light theme only

  ThemeData get currentTheme => lightTheme;

  void toggleTheme() {
    // NeoTaste doesn't support dark mode
    // Keep it as light mode
  }

  void setTheme(bool isDark) {
    // NeoTaste doesn't support dark mode
    // Keep it as light mode
  }
}
