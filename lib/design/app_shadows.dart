import 'package:flutter/material.dart';

/// Global shadow tokens to keep elevation subtle and consistent.
class AppShadows {
  /// Matches customer-side card shadow
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D000000), // 5% black (Colors.black.withValues(alpha: 0.05))
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x14000000), // 8% opacity
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
