import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_typography.dart';

class AppAppBar extends AppBar {
  AppAppBar({
    super.key,
    required String titleText,
    super.centerTitle = false,
    super.actions,
    super.bottom,
    super.leading,
    Color? backgroundColor,
    Color? foregroundColor,
  }) : super(
          title: Text(
            titleText,
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 24, // Stronger presence for the page header
              color: foregroundColor ?? AppColors.textPrimary,
            ),
          ),
          backgroundColor: backgroundColor ?? AppColors.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(
            color: foregroundColor ?? AppColors.textPrimary,
          ),
        );
}
