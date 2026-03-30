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
            Text('Privacy Policy for DiscountBuddy', style: AppTypography.title.copyWith(fontSize: 22)),
            const SizedBox(height: AppSpacing.sm),
            Text('Last Updated: March 30, 2026', style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.xxxl),
            
            _buildSection(
              '1. Who We Are',
              'DiscountBuddy is operated by Mark it up groups Ltd .\n\nWe are the data controller responsible for your personal data.\n\nContact details:\nEmail: contact@discoutbuddy.com\nAddress: 124 City Road, London, EC1V 2NX, United Kingdom',
            ),
            
            _buildSection(
              '2. What Data We Collect',
              'We may collect, use, store, and transfer the following types of personal data:\n\n• Identity Data: first name, last name, username\n• Contact Data: email address, phone number\n• Technical Data: IP address, device type, operating system\n• Usage Data: how you interact with our app',
            ),
            
            _buildSection(
              '3. How We Use Your Data (Legal Basis)',
              'We only use your personal data when legally permitted under UK GDPR.\n\n• Account creation & management (Identity, Contact): Contract\n• Providing services (Identity, Usage): Contract\n• Customer support (Contact): Contract\n• Legal compliance (All relevant data): Legal obligation',
            ),
            
            _buildSection(
              '4. Sharing Your Data',
              'We may share your data with:\n\n• Service providers (hosting, infrastructure)\n• Regulatory authorities where required by law\n\nAll third parties are required to respect the security of your personal data.',
            ),
            
            _buildSection(
              '5. International Transfers',
              'Some of our third-party providers may process data outside the UK. Where this occurs, we ensure safeguards are in place, such as:\n\n• UK adequacy regulations\n• Standard Contractual Clauses (SCCs)',
            ),
            
            _buildSection(
              '6. Data Security',
              'We implement appropriate security measures to prevent unauthorized access, data loss, or data misuse. Access is limited to those with a legitimate business need.',
            ),
            
            _buildSection(
              '7. Data Retention',
              'We retain your personal data only for as long as necessary to provide services and comply with legal obligations. When no longer needed, your data is securely deleted or anonymised.',
            ),
            
            _buildSection(
              '8. Your Legal Rights',
              'Under UK GDPR, you have the right to:\n\n• Access your personal data\n• Request correction of inaccurate data\n• Request deletion of your data\n• Object to processing\n• Request restriction of processing\n• Request transfer of your data (data portability)\n\nYou also have the right to lodge a complaint with the Information Commissioner\'s Office (ICO).',
            ),
            
            _buildSection(
              '9. Children’s Privacy',
              'Our services are not intended for children under 13. We do not knowingly collect data from children.',
            ),
            
            _buildSection(
              '10. Changes to This Policy',
              'We may update this privacy policy from time to time. Any changes will be posted within the app and/or website.',
            ),
            
            _buildSection(
              '11. Contact Us',
              'If you have any questions about this policy:\n\nEmail: contact@discoutbuddy.com\nAddress: 124 City Road, London, EC1V 2NX, United Kingdom',
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
