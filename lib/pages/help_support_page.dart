import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';
import '../design/app_shadows.dart';
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Help & Support',
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Frequently Asked Questions', style: AppTypography.title),
            SizedBox(height: AppSpacing.lg),
            _buildFAQItem(
              'How do I redeem a deal?',
              'Simply navigate to the restaurant page, select the deal you want to use, and show the redemption screen to the staff when you ask for the bill.',
            ),
            _buildFAQItem(
              'Can I use a deal multiple times?',
              'Most deals are available to be used once per day, but please check the specific terms on the deal card for details.',
            ),
            _buildFAQItem(
              'What do I do if a restaurant refuses a deal?',
              'Please contact our support team immediately using the button below. We take this very seriously and will resolve it for you.',
            ),
            _buildFAQItem(
              'How do I update my profile?',
              'Go to the Profile tab and click on "Edit profile" to update your name and other details.',
            ),
            SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: ExpansionTile(
        title: Text(question, style: AppTypography.subtitle.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        )),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        children: [
          Text(answer, style: AppTypography.body.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
