import 'package:flutter/material.dart';


class AppFonts {
  // Graphik Family

  // Graphik Family
  static const String graphik = 'Graphik';
  static const String graphikMedium = 'Graphik-Medium';

  // Semantically defined fonts for easy site-wide changes
  static String? get titleFont => graphik;
  static String? get headingFont => graphik;
  static String? get buttonFont => graphik;
  static String? get bodyFont => graphik;
  static String? get inputFont => graphik;
  static String? get logoFont => graphik;
  static String? get accentFont => graphikMedium;

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
