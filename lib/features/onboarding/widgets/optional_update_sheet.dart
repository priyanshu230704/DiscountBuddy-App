import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/core/theme/app_radius.dart';
import 'package:discount_buddy/core/theme/app_typography.dart';
import 'package:discount_buddy/features/onboarding/models/app_version_info.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';
import 'package:discount_buddy/widgets/generic_bottom_sheet.dart';

/// Optional update bottom sheet — shown once per app session on startup.
class OptionalUpdateSheet extends StatefulWidget {
  final AppVersionInfo versionInfo;

  const OptionalUpdateSheet({super.key, required this.versionInfo});

  static Future<void> show(BuildContext context, AppVersionInfo versionInfo) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => OptionalUpdateSheet(versionInfo: versionInfo),
    );
  }

  @override
  State<OptionalUpdateSheet> createState() => _OptionalUpdateSheetState();
}

class _OptionalUpdateSheetState extends State<OptionalUpdateSheet> {
  bool _isLaunchingStore = false;

  Future<void> _openStore() async {
    final url = widget.versionInfo.storeUrl;
    if (url == null || url.isEmpty) return;

    setState(() => _isLaunchingStore = true);
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) setState(() => _isLaunchingStore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GenericBottomSheet(
        title: 'App Update Available',
        backgroundColor: AppColors.surface,
        footer: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLaunchingStore
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPurple,
                    side: BorderSide(
                      color: AppColors.primaryPurple.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
                    ),
                  ),
                  child: const Text(
                    'Update Later',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppGradientButton(
                  onPressed: _isLaunchingStore ? null : _openStore,
                  isLoading: _isLaunchingStore,
                  height: 48,
                  child: const Text(
                    'Update Now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animation/update.json',
                width: 200,
                height: 140,
                fit: BoxFit.contain,
                repeat: true,
              ),
              const SizedBox(height: 8),
              Text(
                widget.versionInfo.updateMessage ??
                    'Do you want to update now or later?',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.versionInfo.latestVersion != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.08),
                    borderRadius: AppRadius.chip,
                  ),
                  child: Text(
                    'Latest version: ${widget.versionInfo.latestVersion}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
