import 'package:flutter/material.dart';

/// Central color system for the app (shared across customer and merchant).
class AppColors {
  // Brand
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color secondaryPink = Color(0xFFD946EF);
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color secondaryOrange = Color(0xFFEA580C);

  static const Color discount = primaryOrange;
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Merchant accent palette
  static const Color merchantBlue = Color(0xFF3B82F6);
  static const Color merchantIndigo = Color(0xFF6366F1);
  static const Color merchantTeal = Color(0xFF14B8A6);
  static const Color merchantAmber = Color(0xFFF59E0B);

  // Gradients
  static const List<Color> purpleGradientColors = [
    primaryPurple,
    secondaryPink,
  ];
  static const List<Color> orangeGradientColors = [
    primaryOrange,
    secondaryOrange,
  ];

  static const Gradient purpleGradient = LinearGradient(
    colors: purpleGradientColors,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient orangeGradient = LinearGradient(
    colors: orangeGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft background gradient
  static const Gradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF3E8FF), Color(0xFFF7F8FC)], // Soft purple to background
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 1.0],
  );

  // Merchant gradient (deep purple to compliment customer's soft purple)
  static const Gradient merchantGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Surfaces - Matching customer side
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFF1F3F5);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shimmer = Color(0xFFE5E7EB);

  // Text - Matching customer side
  static const Color textDarkest = Color(0xFF1B1436);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);

  // Aliases
  static const Color primary = primaryPurple;
  static const Color secondary = secondaryPink;
  static const Color accent = primaryOrange;
  static const Color white = Colors.white;
  static const Color cardBackground = surface;

  // Legacy compatibility aliases
  static const Gradient heroGradient = orangeGradient;
  static const Gradient primaryGradient = purpleGradient;
}
