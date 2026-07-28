import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/features/auth/data/auth_provider.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'package:discount_buddy/features/onboarding/data/onboarding_provider.dart';

/// Screen that checks onboarding status and routes accordingly
class OnboardingCheckScreen extends StatefulWidget {
  const OnboardingCheckScreen({super.key});

  @override
  State<OnboardingCheckScreen> createState() => _OnboardingCheckScreenState();
}

class _OnboardingCheckScreenState extends State<OnboardingCheckScreen> {
  final AuthProvider _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();
    // Defer until after the first frame — notifyListeners during initState/build is illegal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingAndAuth();
    });
  }

  Future<void> _checkOnboardingAndAuth() async {
    // Wait for AuthProvider to finish initializing
    int attempts = 0;
    while (_authProvider.isLoading && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;

    final onboardingProvider = context.read<OnboardingProvider>();
    await onboardingProvider.checkHasCompletedOnboarding();
    final hasCompletedOnboarding = onboardingProvider.hasCompletedOnboarding;
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
