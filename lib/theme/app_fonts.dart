import 'package:flutter/material.dart';

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

  // HubotSans Family - Most readable for Body, Inputs, and Details
  static const String hubotSans = 'HubotSans';
  static const String hubotSansItalic = 'HubotSans-Italic';

  // Semantically defined fonts for easy site-wide changes
  static const String titleFont = polySansMedian;
  static const String headingFont = polySansBulky;
  static const String buttonFont = polySansMedian;
  static const String bodyFont = hubotSans;
  static const String inputFont = hubotSans;
  static const String logoFont = polySansBulky;

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
