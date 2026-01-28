import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';

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

// Local constants for onboarding screen
class _OnboardingConstants {
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  static const double radiusLarge = 16.0;
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

    // Navigate to login page
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _skipOnboarding() {
    _handleGetStarted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background color
          Positioned.fill(child: Container(color: Colors.white)),
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
                  left: _OnboardingConstants.paddingLarge,
                  right: _OnboardingConstants.paddingLarge,
                  top: _OnboardingConstants.paddingXLarge,
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.9),
                      Colors.white,
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
                    const SizedBox(height: 32),
                    _buildGetStartedButton(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Register",
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageData pageData, int pageIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _OnboardingConstants.paddingLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20), // Further reduced top space
          // Hero Image
          Expanded(
            child: Transform.scale(
              scale: 1.5, // Even larger image size
              child: Image.asset(
                'assets/png/onboarding.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Title
          Text(
            pageData.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Description
          Text(
            pageData.description,
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF4CAF50)
            : Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleGetStarted,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              _OnboardingConstants.radiusLarge,
            ),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Get Started',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
