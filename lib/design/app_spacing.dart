import 'package:flutter/material.dart';

/// Global spacing tokens for consistent layout rhythm.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: xl, vertical: lg);

  static const EdgeInsets cardPadding =
      EdgeInsets.all(lg);

  static const EdgeInsets sectionVertical =
      EdgeInsets.symmetric(vertical: xl);
}

