import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../../providers/theme_provider.dart';
import '../restaurant_details_page.dart';
import '../search_page.dart';
import '../../widgets/skeleton_loader.dart';

/// Discover (Home) Screen - NeoTaste style
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  final PageController _featuredController = PageController();
  int _featuredPage = 0;
  List<Restaurant> _restaurants = [];
  List<Restaurant> _featuredRestaurants = [];
  bool _isLoading = true;
  String _cityName = 'Loading...';
  final List<String> _categories = ['Cafe', 'Restaurant', 'Bar', 'Dessert', 'Drinks'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Defer data loading to avoid blocking main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _featuredController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load city name and restaurants in parallel
      final results = await Future.wait([
        _locationService.getUserCity(),
        _restaurantService.getNearbyRestaurants(
          latitude: 51.5074,
          longitude: -0.1278,
        ),
      ]);

      if (mounted) {
        setState(() {
          _cityName = results[0] as String;
          _restaurants = results[1] as List<Restaurant>;
          _featuredRestaurants = (results[1] as List<Restaurant>).take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cityName = 'London';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Top Section: City selector + Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      // City Selector
                      GestureDetector(
                        onTap: () {
                          // Show city selector
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: NeoTasteColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _cityName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: NeoTasteColors.primary,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: NeoTasteColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Search Icon
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: NeoTasteColors.primary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Featured Deals (Horizontal Scroll)
              if (_isLoading)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        margin: const EdgeInsets.only(right: 16),
                        child: SkeletonLoader(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                )
              else if (_featuredRestaurants.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 280,
                        child: PageView.builder(
                          controller: _featuredController,
                          onPageChanged: (index) {
                            setState(() {
                              _featuredPage = index;
                            });
                          },
                          itemCount: _featuredRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = _featuredRestaurants[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: _FeaturedDealCard(restaurant: restaurant),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Page indicator dots
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _featuredRestaurants.length,
                            (index) => Container(
                              width: _featuredPage == index ? 8 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _featuredPage == index
                                    ? NeoTasteColors.accent
                                    : NeoTasteColors.textDisabled,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

              // Categories (Horizontal Chips)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      final category = index == 0 ? 'All' : _categories[index - 1];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: NeoTasteColors.accent,
                          labelStyle: GoogleFonts.inter(
                            color: isSelected
                                ? NeoTasteColors.primary
                                : NeoTasteColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Restaurant List
              if (_isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: SkeletonLoader(
                        height: 120,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    childCount: 5,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final restaurant = _restaurants[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _RestaurantCard(restaurant: restaurant),
                      );
                    },
                    childCount: _restaurants.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Featured Deal Card
class _FeaturedDealCard extends StatelessWidget {
  final Restaurant restaurant;

  const _FeaturedDealCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsPage(restaurant: restaurant),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Restaurant Image
              CachedNetworkImage(
                imageUrl: restaurant.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: NeoTasteColors.textDisabled,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: NeoTasteColors.textDisabled,
                  child: const Icon(Icons.restaurant, size: 48),
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Deal Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: NeoTasteColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          restaurant.discount.displayText,
                          style: GoogleFonts.inter(
                            color: NeoTasteColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Restaurant Name
                      Text(
                        restaurant.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Offer Text
                      Text(
                        restaurant.discount.description,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
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
    );
  }
}

/// Restaurant List Card
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsPage(restaurant: restaurant),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: NeoTasteColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: restaurant.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 100,
                  height: 100,
                  color: NeoTasteColors.textDisabled,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 100,
                  height: 100,
                  color: NeoTasteColors.textDisabled,
                  child: const Icon(Icons.restaurant),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Name
                    Text(
                      restaurant.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: NeoTasteColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Cuisine + Distance
                    Text(
                      '${restaurant.cuisine} • ${restaurant.distance.toStringAsFixed(1)} km',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: NeoTasteColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Deal Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NeoTasteColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            restaurant.discount.displayText,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: NeoTasteColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Rating
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: NeoTasteColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
