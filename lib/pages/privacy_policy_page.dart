import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../widgets/app_scaffold.dart';
import '../components/app_app_bar.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Privacy Policy',
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PRIVACY POLICY', style: AppTypography.title.copyWith(fontSize: 22)),
            const SizedBox(height: AppSpacing.sm),
            Text('Last Updated: April 6, 2026', style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.xxxl),
            
            _buildSection(
              '1. Introduction',
              'DiscountBuddy (“we”, “our”, “us”) is operated by MarkitUp Group Limited.\n\nWe are committed to protecting your personal data and ensuring transparency in how we collect, use, and store your information in accordance with the UK GDPR and the Data Protection Act 2018.',
            ),
            
            _buildSection(
              '2. Data We Collect',
              'Account Information\nWe collect:\n• Full Name\n• Email Address\n• Phone Number\n• Profile Picture\n• Username\n\nAuthentication Data\n• Email/OTP login users: Passwords are securely stored using hashed encryption (PBKDF2 with SHA256)\n• Google and Apple login users: We do not store passwords\n\nUsage Data\nWe collect user interaction data including:\n• Deal clicks\n• Bookings\n• Reviews\n• App engagement behaviour\n\nDevice & Technical Data\nWe may collect:\n• IP address\n• Device type\n• Operating system\n• Log data via Firebase and server logs\n\nBooking Data\nWe collect and store:\n• Booking date and time\n• Number of guests\n• User contact details (name, email, phone)\n• Restaurant ID\n• Booking status and special requests\n\nMerchant & Analytics Data\n• Restaurant performance metrics\n• Aggregated earnings and engagement\n• QR code redemption data\n\nMystery Guest Data\n• Review submissions (food, service, hygiene, ambience)\n• Supporting evidence such as photos and receipts\n• This data remains anonymous to restaurants',
            ),
            
            _buildSection(
              '3. Location Data',
              'We collect GPS (precise) and approximate location (city/postcode)\n\nLocation data is used only within the app to show nearby restaurants and recommendations\n\nWe do not store user location on our servers',
            ),
            
            _buildSection(
              '4. How We Use Your Data',
              'We use your data to:\n• Operate and maintain the DiscountBuddy platform\n• Enable bookings and restaurant interactions\n• Provide personalised recommendations\n• Rank restaurants using our scoring system\n• Generate analytics for restaurant partners\n• Improve app performance and user experience\n• Prevent fraud and ensure security',
            ),
            
            _buildSection(
              '5. AI & Profiling',
              'We use a ranking system based on:\n• 40% User Ratings\n• 60% Mystery Guest Quality Scores\n\nThis is used only to improve recommendations and does not produce legal or similarly significant effects.',
            ),
            
            _buildSection(
              '6. Legal Basis for Processing',
              'We process your data based on:\n• Contract – to provide our services\n• Legitimate Interest – to improve the platform and analytics\n• Consent – for location and optional features\n• Legal Obligation – to comply with UK law',
            ),
            
            _buildSection(
              '7. Data Sharing',
              'We may share data with:\n\nService Providers\n• AWS (hosting infrastructure)\n• Firebase (notifications)\n• Google and Apple (authentication services)\n• Hostinger (email services)\n\nRestaurant Partners\n• Booking-related data is shared with restaurants to manage reservations\n\nLegal Authorities\n• When required by law\n\nWe do not sell your personal data.',
            ),
            
            _buildSection(
              '8. Data Storage & Security',
              '• Data is stored securely on AWS infrastructure\n• Passwords are encrypted using industry standards\n• Access is restricted to authorised personnel\n• Security measures include encryption and secure APIs',
            ),
            
            _buildSection(
              '9. International Data Transfers',
              'Where data is processed outside the UK, appropriate safeguards are applied in compliance with UK GDPR.',
            ),
            
            _buildSection(
              '10. Data Retention',
              '• Data is stored as long as the user account is active\n• Users can request deletion at any time\n• Some data may be retained where required by law',
            ),
            
            _buildSection(
              '11. Your Rights',
              'You have the right to:\n• Access your personal data\n• Correct inaccurate data\n• Request deletion\n• Restrict processing\n• Object to processing\n• Request data portability\n\nTo exercise your rights, contact:\ndiscountbuddy@markitupgroup.com',
            ),
            
            _buildSection(
              '12. Account Deletion',
              'Users can delete their account using OTP verification.\n\nUpon deletion, personal data is removed unless legally required to retain it.',
            ),
            
            _buildSection(
              '13. Children’s Privacy',
              'This app is not intended for users under 18.\n\nWe do not knowingly collect data from minors.',
            ),
            
            _buildSection(
              '14. Changes to This Policy',
              'We may update this Privacy Policy from time to time.\n\nChanges will be reflected within the app.',
            ),
            
            _buildSection(
              '15. Contact Information',
              'MarkitUp Group Limited\n24h, Riverside Court\nBeaufort Park Way\nChepstow NP16 5UH\nUnited Kingdom\n\nEmail: discountbuddy@markitupgroup.com',
            ),
            
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.title.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.md),
          Text(
            content,
            style: AppTypography.body.copyWith(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
