import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../services/onboarding_service.dart';

/// Screen that checks onboarding status and routes accordingly
class OnboardingCheckScreen extends StatefulWidget {
  const OnboardingCheckScreen({super.key});

  @override
  State<OnboardingCheckScreen> createState() => _OnboardingCheckScreenState();
}

class _OnboardingCheckScreenState extends State<OnboardingCheckScreen> {
  final AuthProvider _authProvider = AuthProvider();
  final OnboardingService _onboardingService = OnboardingService();

  @override
  void initState() {
    super.initState();
    _checkOnboardingAndAuth();
  }

  Future<void> _checkOnboardingAndAuth() async {
    // Wait for AuthProvider to finish initializing
    // Check if it's still loading, wait a bit
    int attempts = 0;
    while (_authProvider.isLoading && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    // Check if user has completed onboarding
    final hasCompletedOnboarding = await _onboardingService
        .hasCompletedOnboarding();

    // Check authentication status
    final isAuthenticated = _authProvider.isAuthenticated;

    if (mounted) {
      if (!hasCompletedOnboarding) {
        Get.offNamed(AppRoutes.onboarding);
      } else if (isAuthenticated) {
        Get.offNamed(AppRoutes.home);
      } else {
        Get.offNamed(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    AppColors.surface,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
