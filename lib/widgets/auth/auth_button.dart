import 'package:flutter/material.dart';
import 'auth_theme.dart';

/// NeoTaste-style Auth Button - Yellow pill-shaped button
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
    return SizedBox(
      width: width ?? double.infinity,
      height: AuthTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthTheme.accent,
          foregroundColor: AuthTheme.background,
          disabledBackgroundColor: AuthTheme.textGrey.withOpacity(0.3),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthTheme.buttonBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AuthTheme.background),
                ),
              )
            : Text(
                text,
                style: AuthTheme.buttonText,
              ),
      ),
    );
  }
}
