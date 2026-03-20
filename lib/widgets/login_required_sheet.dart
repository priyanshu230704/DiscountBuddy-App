import 'package:flutter/material.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/theme/app_fonts.dart';
import 'generic_bottom_sheet.dart';

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
              style: AppFonts.titleStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please login to access all features like bookings, reviews, and redeeming offers.',
              style: AppFonts.bodyStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Login / Sign Up',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            if (isClosable) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: AppFonts.bodyStyle(
                    color: AppColors.textDisabled,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onBackToHome,
                child: Text(
                  'Back to Home',
                  style: AppFonts.bodyStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
