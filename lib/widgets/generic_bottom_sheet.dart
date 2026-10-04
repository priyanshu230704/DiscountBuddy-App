import 'package:discount_buddy/theme/app_colors.dart';

import 'package:discount_buddy/design/app_typography.dart';
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
  final Color backgroundColor;
  final bool centerTitle;

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
    this.backgroundColor = AppColors.white,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Handle bar
            if (showHandle)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
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
                padding: EdgeInsets.fromLTRB(
                  24,
                  showHandle ? 0 : 12,
                  16,
                  title.isNotEmpty ? 4 : 0,
                ),
                child: centerTitle && title.isNotEmpty
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: showCloseButton ? 40 : 0,
                              right: showCloseButton ? 40 : 0,
                            ),
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.title.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (headerAction != null)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: showCloseButton ? 40 : 0,
                                ),
                                child: headerAction!,
                              ),
                            ),
                          if (showCloseButton)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                icon: const Icon(Icons.close),
                                onPressed: onClose ?? () => Navigator.pop(context),
                                color: AppColors.textPrimary,
                              ),
                            ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title.isNotEmpty)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4, right: 8),
                                child: Text(
                                  title,
                                  style: AppTypography.title.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          if (headerAction != null) headerAction!,
                          if (showCloseButton)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              icon: const Icon(Icons.close),
                              onPressed: onClose ?? () => Navigator.pop(context),
                              color: AppColors.textPrimary,
                            ),
                        ],
                      ),
              ),

            // Content
            if (expandChild)
              Expanded(child: child)
            else
              Flexible(child: child),

            // Footer
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}
