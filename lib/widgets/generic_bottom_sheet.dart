import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

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
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: NeoTasteColors.textDisabled,
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
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: NeoTasteColors.textPrimary,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    if (headerAction != null) headerAction!,
                    if (showCloseButton)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose ?? () => Navigator.pop(context),
                        color: NeoTasteColors.textPrimary,
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
