import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discount_buddy/core/theme/app_design.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/components/inputs.dart';
import 'package:discount_buddy/features/profile/data/profile_provider.dart';

/// Page for restaurants to request partnership
class JoinPartnerPage extends StatefulWidget {
  const JoinPartnerPage({super.key});

  @override
  State<JoinPartnerPage> createState() => _JoinPartnerPageState();
}

class _JoinPartnerPageState extends State<JoinPartnerPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _restaurantNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _websiteController = TextEditingController();
  final _commentsController = TextEditingController();

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _contactNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _websiteController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<ProfileProvider>().submitPartnerRequest(
        restaurantName: _restaurantNameController.text.trim(),
        contactName: _contactNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        cityName: _cityController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        comments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
      );

      if (mounted) {
        final provider = context.read<ProfileProvider>();
        if (provider.error == null) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error?.toString() ?? 'Failed to submit request'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xLarge),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            Text('Request Sent', style: AppTypography.title.copyWith(fontSize: 20)),
          ],
        ),
        content: Text(
          'Thank you for your interest! Our team will review your application and reach out to you shortly.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to profile
            },
            child: Text(
              'Close',
              style: AppTypography.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Become a Partner',
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Image/Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              Text(
                'Grow your business with DiscountBuddy',
                textAlign: TextAlign.center,
                style: AppTypography.headline.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Fill out the form below and our partnership team will be in touch with you.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Form Fields
              AppTextField(
                controller: _restaurantNameController,
                label: 'Restaurant Name',
                hintText: 'Enter your restaurant name',
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              
              AppTextField(
                controller: _contactNameController,
                label: 'Contact Name',
                hintText: 'First and last name',
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              
              AppTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'Official business email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hintText: 'Contact phone number',
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              
              AppTextField(
                controller: _cityController,
                label: 'City',
                hintText: 'City where restaurant is located',
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              
              AppTextField(
                controller: _websiteController,
                label: 'Website (Optional)',
                hintText: 'https://...',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppSpacing.lg),
              
              AppTextField(
                controller: _commentsController,
                label: 'Additional Comments (Optional)',
                hintText: 'Tell us a bit about your restaurant...',
                maxLines: 4,
              ),
              
              const SizedBox(height: AppSpacing.xxxl),
              
              Consumer<ProfileProvider>(
                builder: (context, profileProvider, _) {
                  return AppGradientButton(
                    onPressed: profileProvider.isLoading ? null : _submitRequest,
                    isLoading: profileProvider.isLoading,
                    child: const Text('Submit Application'),
                  );
                },
              ),
              
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
