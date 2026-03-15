import 'package:flutter/material.dart';

/// Global shadow tokens to keep elevation subtle and consistent.
class AppShadows {
  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x14111827), // 8% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x1A111827), // 10% opacity
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0x26111827), // 15% opacity
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];
}

