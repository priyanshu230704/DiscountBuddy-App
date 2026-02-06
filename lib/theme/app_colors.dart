import 'package:flutter/material.dart';

class AppColors {
  // Core Palette
  static const Color primary = Color(0xFF4F46E5); // Electric Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Soft Violet
  static const Color success = Color(0xFF22C55E); // Mint Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red

  // Neutral Palette - Light
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);

  // Neutral Palette - Dark
  static const Color backgroundDark = Color(0xFF020617);
  static const Color surfaceDark = Color(
    0xB3020617,
  ); // rgba(2,6,23,0.7) -> 0.7 * 255 = ~179 -> B3 hex
  static const Color textPrimaryDark = Color(0xFFE5E7EB);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color dividerDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF1E293B);

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
