import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/onboarding_service.dart';
import 'onboarding_screen.dart';
import 'auth/login_page.dart';
import 'main_navigation.dart';
import '../providers/theme_provider.dart';

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
    final hasCompletedOnboarding = await _onboardingService.hasCompletedOnboarding();
    
    // Check authentication status
    final isAuthenticated = _authProvider.isAuthenticated;
    
    if (mounted) {
      // Navigate based on onboarding and auth status
      if (!hasCompletedOnboarding) {
        // Show onboarding if not completed
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else if (isAuthenticated) {
        // User is authenticated, go to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainNavigation(themeProvider: ThemeProvider()),
          ),
        );
      } else {
        // User has seen onboarding but not authenticated, go to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3E25F6)),
        ),
      ),
    );
  }
}

