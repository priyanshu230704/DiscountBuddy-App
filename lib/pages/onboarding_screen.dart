import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import 'auth/login_page.dart';

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
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Tasty Meals Delivered Faster Than You Think',
      description: 'Bring your food quickly and safely, ensuring every bite stays hot, fresh, and the way you like it.',
      imageUrl: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400',
      foodCards: [
        FoodCardData(
          title: 'Paneer Butter Masala',
          description: 'Creamy cottage cheese in tomato curry sauce',
          imageUrl: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=200',
          color: const Color(0xFF4CAF50),
        ),
        FoodCardData(
          title: 'Chocolate Cake',
          description: 'Warm, Served with ice Cream',
          imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=200',
          color: const Color(0xFF9C27B0),
        ),
      ],
    ),
    OnboardingPageData(
      title: 'Discover Amazing Restaurants',
      description: 'Explore a wide variety of restaurants, cafes, and food joints near you with exclusive discounts and offers.',
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
      foodCards: [],
      icon: Icons.restaurant_menu,
      iconColor: const Color(0xFF3E25F6),
    ),
    OnboardingPageData(
      title: 'Save More with Exclusive Deals',
      description: 'Get the best discounts and vouchers on your favorite meals. Save money while enjoying delicious food.',
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400',
      foodCards: [],
      icon: Icons.local_offer,
      iconColor: const Color(0xFFFF6B6B),
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

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleGetStarted();
    }
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
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF121212),
                      const Color(0xFF0A0A0A),
                    ],
                  ),
                ),
              ),
            ),
            // Skip button
            Positioned(
              top: 16,
              right: 24,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // PageView content
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPage(_pages[index], index);
              },
            ),
            // Bottom section with indicators and button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _OnboardingConstants.paddingLarge,
                  vertical: _OnboardingConstants.paddingXLarge,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF121212).withOpacity(0.9),
                      const Color(0xFF121212),
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
                    // Next/Get Started button
                    _currentPage == _pages.length - 1
                        ? _buildSwipeableGetStartedButton(isLastPage: true)
                        : _buildNextButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPageData pageData, int pageIndex) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _OnboardingConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 80),
            // Food cards or icon
            if (pageData.foodCards.isNotEmpty)
              ...pageData.foodCards.map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFoodCard(card),
                  ))
            else if (pageData.icon != null)
              _buildIconPage(pageData, pageIndex),
            const SizedBox(height: 60),
            // Title
            Text(
              pageData.title,
              style: const TextStyle(
                color: Colors.white,
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
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 120), // Space for bottom section
          ],
        ),
      ),
    );
  }

  Widget _buildIconPage(OnboardingPageData pageData, int pageIndex) {
    // 3rd page (index 2) uses rounded rectangle, others use circle
    final isThirdPage = pageIndex == 2;
    
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: pageData.iconColor!.withOpacity(0.2),
            shape: isThirdPage ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isThirdPage 
                ? BorderRadius.circular(_OnboardingConstants.radiusLarge)
                : null,
            border: Border.all(
              color: pageData.iconColor!.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            pageData.icon,
            size: 80,
            color: pageData.iconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodCard(FoodCardData card) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(_OnboardingConstants.radiusLarge),
        border: Border.all(
          color: card.color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: card.color.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Food image
          Hero(
            tag: card.title,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                card.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: Colors.white.withOpacity(0.5),
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Food details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Arrow icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
          ),
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
        color: isActive ? const Color(0xFF3E25F6) : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF3E25F6).withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_OnboardingConstants.radiusMedium),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Next',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeableGetStartedButton({required bool isLastPage}) {
    return _SwipeableButton(
      onSwipeComplete: _handleGetStarted,
      onTap: _handleGetStarted,
      showIconAfterText: false, // Remove icon after "Get Started" on 3rd slide
    );
  }
}

/// Swipeable button widget that can be dragged left to right
class _SwipeableButton extends StatefulWidget {
  final VoidCallback onSwipeComplete;
  final VoidCallback onTap;
  final bool showIconAfterText;

  const _SwipeableButton({
    required this.onSwipeComplete,
    required this.onTap,
    this.showIconAfterText = true,
  });

  @override
  State<_SwipeableButton> createState() => _SwipeableButtonState();
}

class _SwipeableButtonState extends State<_SwipeableButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  double _maxDragDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isCompleted) return;

    setState(() {
      _dragPosition += details.delta.dx;
      if (_dragPosition < 0) {
        _dragPosition = 0;
      } else if (_dragPosition > _maxDragDistance) {
        _dragPosition = _maxDragDistance;
        // Reached the end, navigate to login
        _completeSwipe();
      }
    });

    // Animate scale on drag
    if (_dragPosition > 0 && !_animationController.isAnimating) {
      _animationController.forward();
    }
  }

  void _completeSwipe() {
    if (_isCompleted) return;
    
    setState(() {
      _isCompleted = true;
    });
    _animationController.reverse();
    // Navigate immediately when reaching the end
    widget.onSwipeComplete();
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isCompleted) return;

    // Check if reached the end (within 5 pixels tolerance)
    if (_dragPosition >= _maxDragDistance - 5) {
      _completeSwipe();
    } else {
      // Snap back if not reached the end
      _animationController.reverse();
      setState(() {
        _dragPosition = 0.0;
      });
    }
  }

  void _onTap() {
    if (!_isCompleted) {
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidth = MediaQuery.of(context).size.width - 48; // Account for padding
    _maxDragDistance = buttonWidth - 60; // Full width minus button size
    final progress = _maxDragDistance > 0 ? _dragPosition / _maxDragDistance : 0.0;

    return GestureDetector(
      onTap: _onTap,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(_OnboardingConstants.radiusLarge),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Background progress fill
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: buttonWidth * progress,
              decoration: BoxDecoration(
                color: const Color(0xFF3E25F6).withOpacity(0.3),
                borderRadius: BorderRadius.circular(_OnboardingConstants.radiusLarge),
              ),
            ),
            // Swipeable button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              left: _dragPosition.clamp(0.0, buttonWidth - 60),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E25F6),
                    shape: BoxShape.circle,
                    // Show glow only when dragging (dragPosition > 0)
                    boxShadow: _dragPosition > 0
                        ? [
                            BoxShadow(
                              color: const Color(0xFF3E25F6).withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Text overlay
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _dragPosition > 10 ? 0.0 : 1.0,
                child: widget.showIconAfterText
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Get Started',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for onboarding page content
class OnboardingPageData {
  final String title;
  final String description;
  final String imageUrl;
  final List<FoodCardData> foodCards;
  final IconData? icon;
  final Color? iconColor;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.foodCards,
    this.icon,
    this.iconColor,
  });
}

/// Data class for food card content
class FoodCardData {
  final String title;
  final String description;
  final String imageUrl;
  final Color color;

  FoodCardData({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.color,
  });
}
