import 'package:discount_buddy/theme/app_colors.dart';

import 'package:discount_buddy/theme/app_fonts.dart';
import 'package:flutter/material.dart';

class GenericBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showHandle;
  final bool showCloseButton;
  final Widget? footer;
  final bool expandChild;
  final VoidCallback? onClose;
  final Widget? headerAction;

  const GenericBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.showHandle = true,
    this.showCloseButton = true,
    this.footer,
    this.expandChild = false,
    this.onClose,
    this.headerAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            if (showHandle)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

            // Header (Title + Action + Close Button)
            if (title.isNotEmpty || showCloseButton || headerAction != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    if (title.isNotEmpty)
                      Expanded(
                        child: Text(
                          title,
                          style: AppFonts.bodyStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    ?headerAction,
                    if (showCloseButton)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose ?? () => Navigator.pop(context),
                        color: AppColors.textPrimary,
                      ),
                  ],
                ),
              ),

            if (title.isNotEmpty || showCloseButton) const SizedBox(height: 8),

            // Content
            if (expandChild) Expanded(child: child) else Flexible(child: child),

            // Footer
            ?footer,
          ],
        ),
      ),
    );
  }
}
