import 'package:discount_buddy/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
