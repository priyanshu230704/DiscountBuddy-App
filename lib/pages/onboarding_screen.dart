import 'package:discount_buddy/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';

/// Data class for onboarding page content
class OnboardingPageData {
  final String title;
  final String description;
  final String? imagePath;

  OnboardingPageData({
    required this.title,
    required this.description,
    this.imagePath,
  });
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
    final size = MediaQuery.of(context).size;
    final scale = (size.width / 390).clamp(0.7, 1.05);

    return Scaffold(
      body: Stack(
        children: [
          // Premium Mesh Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEDE7FF),
                    Color(0xFFFFF2F9),
                    Color(0xFFF0F7FF),
                  ],
                ),
              ),
            ),
          ),

          // Decorative Glow Bubbles (Richer colors and center positioning)
          Positioned(
            top: -180 * scale,
            left: -50 * scale,
            right: -50 * scale,
            child: Center(
              child: _GlowBubble(
                size: 600 * scale,
                color: const Color(0xFFCBB2FF).withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            bottom: -200 * scale,
            left: -50 * scale,
            right: -50 * scale,
            child: Center(
              child: _GlowBubble(
                size: 700 * scale,
                color: const Color(0xFFFFB2D9).withValues(alpha: 0.4),
              ),
            ),
          ),

          // INTERACTIVE BACKGROUND ICONS
          // These move based on PageView scroll progress
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double scrollProgress = 0.0;
              if (_pageController.hasClients &&
                  _pageController.position.hasContentDimensions) {
                scrollProgress = _pageController.page ?? 0.0;
              }

              return Stack(
                children: [
                  // Icon 1: Sushi (Moves left/right)
                  Positioned(
                    top: 150 * scale,
                    left: (20 - (scrollProgress * 40)) * scale,
                    child: Opacity(
                      opacity: 0.6,
                      child: _AnimatedIcon(
                        duration: const Duration(seconds: 4),
                        offset: 15,
                        child: Transform.rotate(
                          angle: scrollProgress * 0.5,
                          child: Image.asset(
                            'assets/png/sushi_icon.png',
                            width: 100 * scale,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Icon 2: Burger (Moves up/down and sideways)
                  Positioned(
                    bottom: 250 * scale,
                    right: (10 + (scrollProgress * 50)) * scale,
                    child: Opacity(
                      opacity: 0.5,
                      child: _AnimatedIcon(
                        duration: const Duration(seconds: 5),
                        offset: 20,
                        child: Transform.rotate(
                          angle: -scrollProgress * 0.3,
                          child: Image.asset(
                            'assets/png/burger_icon.png',
                            width: 120 * scale,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Icon 3: Discount Tag (Moves diagonally)
                  Positioned(
                    top: (100 + (scrollProgress * 30)) * scale,
                    right: (30 + (scrollProgress * 60)) * scale,
                    child: Opacity(
                      opacity: 0.7,
                      child: _AnimatedIcon(
                        duration: const Duration(seconds: 3),
                        offset: 12,
                        child: Transform.rotate(
                          angle: -0.2 + (scrollProgress * 0.2),
                          child: Image.asset(
                            'assets/png/discount_tag_icon.png',
                            width: 80 * scale,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Icon 4: Another Sushi (Bottom Left)
                  Positioned(
                    bottom: 120 * scale,
                    left: (-20 + (scrollProgress * 30)) * scale,
                    child: Opacity(
                      opacity: 0.4,
                      child: _AnimatedIcon(
                        duration: const Duration(seconds: 6),
                        offset: 25,
                        child: Image.asset(
                          'assets/png/sushi_icon.png',
                          width: 70 * scale,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: 24 * scale,
                      top: 16 * scale,
                    ),
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: AppFonts.bodyStyle(
                          color: const Color(0xFF5F567A).withValues(alpha: 0.7),
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

                // PageView content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], index, scale);
                    },
                  ),
                ),

                // Bottom section
                Padding(
                  padding: EdgeInsets.all(32 * scale),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) =>
                              _buildPageIndicator(index == _currentPage, scale),
                        ),
                      ),
                      SizedBox(height: 32 * scale),
                      _buildGetStartedButton(scale),
                      SizedBox(height: 24 * scale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppFonts.bodyStyle(
                              color: const Color(
                                0xFF5F567A,
                              ).withValues(alpha: 0.7),
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Register",
                              style: AppFonts.bodyStyle(
                                color: const Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w800,
                                fontSize: 14 * scale,
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
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageData pageData, int pageIndex, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * scale),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SPACER FOR ICONS TO BREATHE
          const Spacer(flex: 4),
          Text(
            pageData.title,
            style: AppFonts.titleStyle(
              color: const Color(0xFF1B1436),
              fontSize: 34 * scale,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.8,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20 * scale),
          Text(
            pageData.description,
            style: AppFonts.bodyStyle(
              color: const Color(0xFF5F567A).withValues(alpha: 0.8),
              fontSize: 17 * scale,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive, double scale) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 * scale : 8 * scale,
      height: 8 * scale,
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
              )
            : null,
        color: isActive ? null : const Color(0xFF2E1A47).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4 * scale),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildGetStartedButton(double scale) {
    return Container(
      width: double.infinity,
      height: 58 * scale,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleGetStarted,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * scale),
          ),
        ),
        child: Text(
          'Get Started',
          style: AppFonts.titleStyle(
            fontSize: 19 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  const _GlowBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.3), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _AnimatedIcon extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double offset;

  const _AnimatedIcon({
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.offset = 10,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: duration,
      tween: Tween<double>(begin: 0, end: 1),
      onEnd: () {},
      builder: (context, value, child) {
        // Continuous sine-wave-like movement
        final move = Curves.easeInOutSine.transform(
          value > 0.5 ? (1 - value) * 2 : value * 2,
        );
        return Transform.translate(
          offset: Offset(0, offset * move),
          child: child,
        );
      },
      child: child,
    );
  }
}
