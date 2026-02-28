import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Color
  static const Color primary = Color(0xFFA93BE8); // Royal Purple

  // Brand Gradient (Hero Sections Only)
  static const Gradient brandGradient = LinearGradient(
    colors: [
      Color(0xFFFF2E88),
      Color(0xFFA93BE8),
      Color(0xFFFF7A00),
      Color(0xFFFFC300),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Success State
  static const Color success = Color(0xFF16A34A);

  // Urgency / Discount Accent
  static const Color accent = Color(0xFFFF7A00);

  // Main Background
  static const Color background = Color(0xFFF8F9FC);

  // Card Background
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);

  // Primary Text
  static const Color textPrimary = Color(0xFF111827);

  // Secondary Text
  static const Color textSecondary = Color(0xFF6B7280);

  // Disabled Text / Borders
  static const Color textDisabled = Color(0xFFD1D5DB); // Gray-300

  // Error state
  static const Color error = Color(0xFFEF4444); // Red

  // Opacity variants for const contexts
  static const Color textPrimary12 = Color(0x1F111827);
  static const Color textPrimary26 = Color(0x42111827);
  static const Color textPrimary38 = Color(0x61111827);
  static const Color textPrimary45 = Color(0x73111827);
  static const Color textPrimary54 = Color(0x8A111827);
  static const Color textPrimary87 = Color(0xDE111827);

  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white38 = Color(0x61FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
}
