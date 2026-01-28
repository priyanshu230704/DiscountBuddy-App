import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_theme.dart';

/// NeoTaste-style Auth Text Field - Minimal rounded input with placeholder only
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
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      style: AuthTheme.bodyText,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: validator,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: AuthTheme.hintText,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        counterText: "", // Hide the default character counter
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthTheme.inputBorderRadius),
          borderSide: BorderSide(
            color: AuthTheme.textGrey.withOpacity(0.5),
            width: AuthTheme.inputBorderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthTheme.inputBorderRadius),
          borderSide: BorderSide(
            color: AuthTheme.textGrey.withOpacity(0.5),
            width: AuthTheme.inputBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthTheme.inputBorderRadius),
          borderSide: BorderSide(
            color: AuthTheme.accent,
            width: AuthTheme.inputBorderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthTheme.inputBorderRadius),
          borderSide: const BorderSide(
            color: Colors.red,
            width: AuthTheme.inputBorderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthTheme.inputBorderRadius),
          borderSide: const BorderSide(
            color: Colors.red,
            width: AuthTheme.inputBorderWidth,
          ),
        ),
        errorStyle: GoogleFonts.inter(color: Colors.red, fontSize: 12),
        suffixIcon: showToggle && onToggleVisibility != null
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AuthTheme.textGrey,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }
}
