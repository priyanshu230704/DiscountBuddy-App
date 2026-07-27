import 'package:flutter/material.dart';
import 'package:discount_buddy/features/auth/widgets/auth_theme.dart';

/// Discount Buddy CTA Button – solid primary blue with white text
class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = !isLoading && onPressed != null;

    return SizedBox(
      width: width ?? double.infinity,
      height: AuthTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? AuthTheme.accent
              : AuthTheme.textGrey.withValues(alpha: 0.3),
          disabledBackgroundColor: AuthTheme.textGrey.withValues(alpha: 0.3),
          foregroundColor: AuthTheme.cardBackground, // white
          shadowColor: AuthTheme.accent.withValues(alpha: 0.25),
          elevation: enabled ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthTheme.buttonBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(text, style: AuthTheme.buttonText),
      ),
    );
  }
}
