import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../design/app_radius.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../components/buttons.dart';
import 'login_page.dart';
import 'register_page.dart';

/// Entry Screen - Login/Signup selector using app design system.
class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.xLarge,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_dining,
                  size: 60,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: AppSpacing.xxl + AppSpacing.xxl),
              Text(
                'Discover the best food deals around you',
                style: AppTypography.headline,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Save money at your favorite restaurants',
                style: AppTypography.subtitle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xxxl * 2),
              PrimaryButton(
                label: 'Continue with Email',
                onPressed: () => _navigateTo(context, const RegisterPage()),
                expand: true,
              ),
              SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Continue with Mobile Number',
                onPressed: () => _navigateTo(context, const RegisterPage()),
                expand: true,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _navigateTo(context, const LoginPage()),
                child: Text(
                  'Already have an account? Log in',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
      ),
    );
  }
}
