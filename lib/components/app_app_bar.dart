import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_typography.dart';

class AppAppBar extends AppBar {
  AppAppBar({
    super.key,
    required String titleText,
    bool centerTitle = false,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
  }) : super(
          title: Text(titleText, style: AppTypography.title),
          centerTitle: centerTitle,
          backgroundColor: AppColors.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: actions,
          bottom: bottom,
        );
}

