import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/core/theme/app_typography.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'package:discount_buddy/widgets/generic_bottom_sheet.dart';

class LoginRequiredSheet extends StatelessWidget {
  final bool isClosable;
  final VoidCallback? onBackToHome;

  const LoginRequiredSheet({
    super.key,
    this.isClosable = true,
    this.onBackToHome,
  });

  static Future<void> show(
    BuildContext context, {
    bool isClosable = true,
    VoidCallback? onBackToHome,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: isClosable,
      enableDrag: isClosable,
      backgroundColor: Colors.transparent,
      builder: (context) => PopScope(
        canPop: isClosable,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && onBackToHome != null) {
            onBackToHome();
          }
        },
        child: LoginRequiredSheet(
          isClosable: isClosable,
          onBackToHome: onBackToHome,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GenericBottomSheet(
      title: 'Login Required',
      showCloseButton: isClosable,
      onClose: isClosable ? () => Navigator.pop(context) : null,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Join DiscountBuddy',
                style: AppTypography.headline.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please login to access all features like bookings, reviews, and redeeming offers.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Get.offAllNamed(AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Login / Sign Up',
                      style: AppTypography.button),
                ),
              ),
              if (isClosable) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Maybe Later',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textDisabled,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onBackToHome,
                  child: Text(
                    'Back to Home',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
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
