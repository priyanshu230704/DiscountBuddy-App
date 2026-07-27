import 'package:flutter/material.dart';
import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/core/theme/app_radius.dart';
import 'package:discount_buddy/core/theme/app_shadows.dart';

class AppGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final bool isLoading;

  const AppGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 54,
    this.gradient,
    this.borderRadius,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppRadius.button;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? (gradient ?? AppColors.purpleGradient)
            : LinearGradient(
                colors: [
                  AppColors.textDisabled.withValues(alpha: 0.5),
                  AppColors.textDisabled.withValues(alpha: 0.3),
                ],
              ),
        borderRadius: effectiveBorderRadius,
        boxShadow: onPressed != null ? AppShadows.card : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: effectiveBorderRadius,
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : child,
      ),
    );
  }
}
