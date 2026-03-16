import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  // PolySans Families - Best for Titles, Buttons, and Accents
  static const String polySansNeutral = 'PolySans-Neutral';
  static const String polySansMedian = 'PolySans-Median';
  static const String polySansBulky = 'PolySans-Bulky';
  static const String polySansSlim = 'PolySans-Slim';
  
  static const String polySansNeutralWide = 'PolySans-NeutralWide';
  static const String polySansMedianWide = 'PolySans-MedianWide';
  static const String polySansBulkyWide = 'PolySans-BulkyWide';
  static const String polySansSlimWide = 'PolySans-SlimWide';

  // HubotSans Family (Legacy)
  static const String hubotSans = 'HubotSans';
  static const String hubotSansItalic = 'HubotSans-Italic';

  // Semantically defined fonts for easy site-wide changes - Now using Poppins
  static String? get titleFont => GoogleFonts.poppins().fontFamily;
  static String? get headingFont => GoogleFonts.poppins().fontFamily;
  static String? get buttonFont => GoogleFonts.poppins().fontFamily;
  static String? get bodyFont => GoogleFonts.poppins().fontFamily;
  static String? get inputFont => GoogleFonts.poppins().fontFamily;
  static String? get logoFont => GoogleFonts.poppins().fontFamily;

  // Utility methods to get TextStyle quickly
  static TextStyle titleStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: titleFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  static TextStyle bodyStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: bodyFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }
}
