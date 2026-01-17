import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

/// Skeleton loader widget for loading states
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: NeoTasteColors.textDisabled.withOpacity(0.3),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(NeoTasteColors.accent),
        ),
      ),
    );
  }
}
