import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

            // Header (Title + Action + Close Button)
            if (title.isNotEmpty || showCloseButton || headerAction != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    if (title.isNotEmpty)
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.headlineSmall,
                        ),
                      )
                    else
                      const Spacer(),
                    if (headerAction != null) headerAction!,
                    if (showCloseButton)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose ?? () => Navigator.pop(context),
                        color: theme.iconTheme.color,
                      ),
                  ],
                ),
              ),

            if (title.isNotEmpty || showCloseButton) const SizedBox(height: 8),

            // Content
            if (expandChild) Expanded(child: child) else Flexible(child: child),

            // Footer
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}
