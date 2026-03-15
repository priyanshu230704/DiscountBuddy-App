import 'package:discount_buddy/theme/app_fonts.dart';
import 'package:flutter/material.dart';

class OccupancyTag extends StatelessWidget {
  final String? occupancy;
  final bool isSmall;

  const OccupancyTag({super.key, this.occupancy, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    if (occupancy == null || occupancy!.isEmpty) return const SizedBox.shrink();

    Color bgColor;
    Color textColor;
    String label;

    switch (occupancy!.toLowerCase()) {
      case 'available':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Available';
        break;
      case 'busy':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFEF6C00);
        label = 'Busy';
        break;
      case 'full':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        label = 'Full';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
      ),
      child: Text(
        label,
        style: AppFonts.bodyStyle(
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
