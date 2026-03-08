import 'package:flutter/material.dart';

/// Discount Buddy – Clean, Modern, Premium Color System
class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────────
  /// Primary brand purple
  static const Color primaryPurple = Color(0xFF8B5CF6);
  /// Secondary brand pink/magenta
  static const Color secondaryPink = Color(0xFFD946EF);
  /// Primary brand orange (accent)
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color secondaryOrange = Color(0xFFEA580C);

  /// Urgency / discount accent
  static const Color discount = primaryOrange;

  /// Success (confirmed bookings, redemption, verified badges)
  static const Color success = Color(0xFF10B981);

  /// Destructive / error
  static const Color error = Color(0xFFEF4444);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const List<Color> purpleGradientColors = [primaryPurple, secondaryPink];
  static const List<Color> orangeGradientColors = [primaryOrange, secondaryOrange];

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

  // ── Surfaces ──────────────────────────────────────────────────────────────
  /// Default app background – neutral light grey
  static const Color background = Color(0xFFF9FAFB);

  /// Card background – clean white
  static const Color surface = Color(0xFFFFFFFF);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);

  // ── Aliases ──────────────────────────────────────────────────────────────
  static const Color primary = primaryPurple;
  static const Color secondary = secondaryPink;
  static const Color accent = primaryOrange;
  static const Color white = Colors.white;

  // Legacy compatibility aliases
  static const Gradient heroGradient = orangeGradient;
  static const Gradient primaryGradient = purpleGradient;
}
