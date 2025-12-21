import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../../widgets/blurred_ellipse_background.dart';
import '../../widgets/common_search_bar.dart';
import '../../widgets/border_gradient.dart';
import '../../utils/constants.dart';
import 'dart:ui';
import '../restaurant_details_page.dart';
import '../browse_page.dart';

/// Home page with search, categories, banner, and featured restaurants
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String? _error;
  String _cityName = 'Loading...';

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _loadCityName();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCityName() async {
    try {
      final city = await _locationService.getUserCity();
      setState(() {
        _cityName = city;
      });
    } catch (e) {
      setState(() {
        _cityName = 'London';
      });
    }
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final restaurants = await _restaurantService.getNearbyRestaurants(
        latitude: 51.5074,
        longitude: -0.1278,
      );
      setState(() {
        _restaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const BlurredEllipseBackground(),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _loadRestaurants,
              child: CustomScrollView(
                slivers: [
                  // Custom Header with Location and Search
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium,
                        vertical: AppConstants.paddingLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    AppConstants.primaryColorValue,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(AppConstants.primaryColorValue),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _cityName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.notifications),
                                color: Colors.grey[300],
                                onPressed: () {
                                  // Navigate to notifications
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.paddingSmall),
                          // Search Bar
                          CommonSearchBar(
                            controller: _searchController,
                            hintText: 'Search...',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BrowsePage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Featured Restaurants Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.paddingMedium,
                        0,
                        AppConstants.paddingMedium,
                        AppConstants.paddingSmall,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.grey[600]!.withOpacity(0.0),
                                    Colors.grey[600]!.withOpacity(0.3),
                                    Colors.grey[600]!.withOpacity(0.6),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Text(
                              'FEATURED RESTAURANTS',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.grey[600]!.withOpacity(0.6),
                                    Colors.grey[600]!.withOpacity(0.3),
                                    Colors.grey[600]!.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Featured Restaurants Carousel
                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 320,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (_error != null)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 320,
                        child: Center(
                          child: Text(
                            'Error loading restaurants',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                      ),
                    )
                  else if (_restaurants.isEmpty)
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 320,
                        child: Center(
                          child: Text(
                            'No restaurants found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: _FeaturedRestaurantsCarousel(
                        restaurants: _restaurants,
                      ),
                    ),
                  // Banner
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium,
                        vertical: AppConstants.paddingSmall,
                      ),
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(AppConstants.primaryColorValue),
                            const Color(
                              AppConstants.primaryColorValue,
                            ).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusLarge,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -50,
                            top: -50,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(
                              AppConstants.paddingMedium,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Save More, Dine More!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  'Get up to 50% off at top restaurants',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const BrowsePage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(
                                      AppConstants.primaryColorValue,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Explore Now',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Featured Restaurants Carousel Widget
class _FeaturedRestaurantsCarousel extends StatefulWidget {
  final List<Restaurant> restaurants;

  const _FeaturedRestaurantsCarousel({
    required this.restaurants,
  });

  @override
  State<_FeaturedRestaurantsCarousel> createState() =>
      _FeaturedRestaurantsCarouselState();
}

class _FeaturedRestaurantsCarouselState
    extends State<_FeaturedRestaurantsCarousel> {
  PageController? _pageController;
  static const int _multiplier = 1000;
  int _totalPages = 1;
  int _currentPage = 0;
  int _itemCount = 0;

  void _initializePageController(int itemCount) {
    if (itemCount == 0 || _itemCount == itemCount) return;
    _itemCount = itemCount;

    if (itemCount == 1) {
      _totalPages = 1;
      _currentPage = 0;
    } else {
      _totalPages = itemCount * _multiplier;
      _currentPage = (_totalPages / 2).round();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.85; // Card width - larger to show partial cards
    final paddingPerSide = 8.0; // Padding on each side to show partial cards
    final viewportFraction = (cardWidth + (paddingPerSide * 2)) / screenWidth;

    _pageController?.dispose();
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: viewportFraction,
    );

    _pageController?.addListener(_onPageScroll);
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    if (_itemCount == 0) return;
    if (page < _itemCount) {
      final newPage = page + (_itemCount * (_multiplier ~/ 2));
      if (_pageController?.hasClients ?? false) {
        _pageController?.jumpToPage(newPage);
      }
    } else if (page > _totalPages - _itemCount) {
      final newPage = page - (_itemCount * (_multiplier ~/ 2));
      if (_pageController?.hasClients ?? false) {
        _pageController?.jumpToPage(newPage);
      }
    }
  }

  void _onPageScroll() {}

  int _getCurrentRestaurantIndex() {
    return _getRestaurantIndex(_currentPage);
  }

  @override
  void dispose() {
    _pageController?.removeListener(_onPageScroll);
    _pageController?.dispose();
    super.dispose();
  }

  int _getRestaurantIndex(int pageIndex) {
    if (_itemCount == 0) return 0;
    return pageIndex % _itemCount;
  }

  @override
  Widget build(BuildContext context) {
    final featuredRestaurants = widget.restaurants.take(5).toList();
    if (featuredRestaurants.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_itemCount != featuredRestaurants.length) {
      _initializePageController(featuredRestaurants.length);
    }

    if (_pageController == null) {
      return const SizedBox(
        height: 320,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentRestaurantIndex = _getCurrentRestaurantIndex();
    final totalPagesForBuilder = featuredRestaurants.length == 1
        ? 1
        : featuredRestaurants.length * _multiplier;

    final horizontalPadding = 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final cardWidth = screenWidth * 0.85;
            final imageAspectRatio = 16 / 10;
            final imageHeight = (cardWidth / imageAspectRatio) * 0.75; // Further reduced height
            final cardPadding = 14.0;
            final contentHeight = 80.0; // Further reduced content height
            final calculatedMinHeight = imageHeight + cardPadding + contentHeight + 10;

            return SizedBox(
              height: calculatedMinHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -horizontalPadding,
                    right: -horizontalPadding,
                    top: 0,
                    bottom: 0,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: totalPagesForBuilder,
                      physics: featuredRestaurants.length == 1
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        final restaurantIndex = _getRestaurantIndex(index);
                        final screenWidth = MediaQuery.of(context).size.width;
                        final cardWidth = screenWidth * 0.85;
                        final paddingPerSide = 8.0;
                        return AnimatedBuilder(
                          animation: _pageController!,
                          builder: (context, child) {
                            double scale = 1.0;
                            double opacity = 1.0;
                            if (_pageController?.hasClients ?? false) {
                              final page = _pageController!.page ??
                                  _currentPage.toDouble();
                              final difference = (page - index).abs();

                              if (difference > 0.5) {
                                scale = 0.92;
                                opacity = 0.7;
                              } else if (difference > 0.0) {
                                final t = (difference / 0.5).clamp(0.0, 1.0);
                                scale = 1.0 - (t * 0.08);
                                opacity = 1.0 - (t * 0.3);
                              }
                            } else {
                              if (index != _currentPage) {
                                scale = 0.92;
                                opacity = 0.7;
                              }
                            }

                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: paddingPerSide),
                              child: Center(
                                child: Transform.scale(
                                  scale: scale,
                                  alignment: Alignment.center,
                                  child: Opacity(
                                    opacity: opacity,
                                    child: SizedBox(
                                      width: cardWidth,
                                      child: _FeaturedRestaurantCard(
                                        restaurant: featuredRestaurants[restaurantIndex],
                                        index: restaurantIndex,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            featuredRestaurants.length,
            (index) => _FeaturedPageIndicatorDot(
              isActive: index == currentRestaurantIndex,
            ),
          ),
        ),
      ],
    );
  }
}

/// Featured Restaurant Card
class _FeaturedRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final int index;

  const _FeaturedRestaurantCard({
    required this.restaurant,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return _FeaturedRestaurantCardContent(
      restaurant: restaurant,
      index: index,
    );
  }
}

class _FeaturedRestaurantCardContent extends StatelessWidget {
  final Restaurant restaurant;
  final int index;

  const _FeaturedRestaurantCardContent({
    required this.restaurant,
    required this.index,
  });

  Color _getEllipseColor() {
    final colors = [
      const Color(0xFF3E25F6), // Purple
      Colors.yellow,
      Colors.orange,
      Colors.green,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsPage(
              restaurant: restaurant,
            ),
          ),
        );
      },
      child: BorderGradient(
        borderWidth: 0.5,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B1F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: restaurant.imageUrl,
                    width: double.infinity,
                    height: 130,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 130,
                      color: const Color(0xFF2B2D30),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 130,
                      color: const Color(0xFF2B2D30),
                      child: const Icon(
                        Icons.restaurant,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                // Restaurant Info
                Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Blurred ellipse background for whole text section
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                          child: Transform.translate(
                            offset: const Offset(0, 25),
                            child: Container(
                              width: 200,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _getEllipseColor().withOpacity(0.5),
                                borderRadius: BorderRadius.circular(35),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            restaurant.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            restaurant.cuisine,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  restaurant.address,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page Indicator Dot
class _FeaturedPageIndicatorDot extends StatelessWidget {
  const _FeaturedPageIndicatorDot({
    required this.isActive,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 8 : 6,
      height: isActive ? 8 : 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
      ),
    );
  }
}
