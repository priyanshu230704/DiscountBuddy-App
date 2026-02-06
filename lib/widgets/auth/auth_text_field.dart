import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Auth Text Field - Updated to standard design system
class AuthTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onToggleVisibility;
  final bool showToggle;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final AutovalidateMode? autovalidateMode;

  const AuthTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onToggleVisibility,
    this.showToggle = false,
    this.focusNode,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.maxLength,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      style: theme.textTheme.bodyLarge,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: validator,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        filled: true,
        fillColor: theme.cardTheme.color,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 16,
        ),
        counterText: "", // Hide the default character counter
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
        suffixIcon: showToggle && onToggleVisibility != null
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }
}
