import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import 'auth/entry_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Data class for onboarding page content
class OnboardingPageData {
  final String title;
  final String description;

  OnboardingPageData({required this.title, required this.description});
}

/// Onboarding screen with swipeable pages
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Explore top restaurants around you',
      description:
          'Discover the best dining spots and hidden gems in your city with ease.',
    ),
    OnboardingPageData(
      title: 'Discover Amazing Restaurants',
      description:
          'Explore a wide variety of restaurants, cafes, and food joints near you with exclusive discounts and offers.',
    ),
    OnboardingPageData(
      title: 'Save More with Exclusive Deals',
      description:
          'Get the best discounts and vouchers on your favorite meals. Save money while enjoying delicious food.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _handleGetStarted() async {
    // Mark onboarding as completed
    await OnboardingService().completeOnboarding();

    // Navigate to entry screen (Login/Register selection)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const EntryScreen()),
      );
    }
  }

  void _skipOnboarding() {
    _handleGetStarted();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(color: theme.scaffoldBackgroundColor),
          ),

          // Main Content
          Column(
            children: [
              // PageView content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], index);
                  },
                ),
              ),

              // Bottom section with indicators and button
              Container(
                padding: EdgeInsets.only(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  top: AppSpacing.xl,
                  bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.scaffoldBackgroundColor.withOpacity(0.0),
                      theme.scaffoldBackgroundColor.withOpacity(0.9),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => _buildPageIndicator(index == _currentPage),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildGetStartedButton(),
                  ],
                ),
              ),
            ],
          ),

          // Skip button
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text(
                  'Skip',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageData pageData, int pageIndex) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60), // Top spacing
          // Hero Image
          Expanded(
            child: Transform.scale(
              scale: 1.0,
              child: Image.asset(
                'assets/png/onboarding.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Title
          Text(
            pageData.title,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Description
          Text(
            pageData.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          // Extra spacing at bottom to push content up from gradient/buttons
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : (isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return Container(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleGetStarted,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: const Text(
          'Get Started',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
