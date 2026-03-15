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
  }) : super(
          title: Text(titleText, style: AppTypography.title),
          backgroundColor: AppColors.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        );
}

