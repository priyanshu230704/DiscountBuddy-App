import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../../providers/theme_provider.dart';
import '../restaurant_details_page.dart';
import '../../widgets/city_selector_modal.dart';

/// Home page with sections for nearby restaurants and saved lists
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _cityName = 'London';

  @override
  void initState() {
    super.initState();
    _loadCityName();
    _loadRestaurants();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterRestaurants();
  }

  void _filterRestaurants() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredRestaurants = _restaurants;
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredRestaurants = _restaurants.where((restaurant) {
          return restaurant.name.toLowerCase().contains(query) ||
              restaurant.cuisine.toLowerCase().contains(query) ||
              restaurant.description.toLowerCase().contains(query);
        }).toList();
      }
    });
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
    });

    try {
      final restaurants = await _restaurantService.getNearbyRestaurants(
        latitude: 51.5074,
        longitude: -0.1278,
      );
      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Convert km to miles
  double _kmToMiles(double km) {
    return km * 0.621371;
  }

  // Generate offer tags based on discount
  List<String> _getOfferTags(Restaurant restaurant) {
    final tags = <String>[];
    final desc = restaurant.discount.description.toLowerCase();

    // Main discount tag
    switch (restaurant.discount.type) {
      case '2for1':
        if (desc.contains('wings')) {
          tags.add('2for1 Signature Wings');
        } else if (desc.contains('rodizio')) {
          tags.add('2for1 Rodizio');
        } else if (desc.contains('course')) {
          tags.add('2for1 Main Course');
        } else if (desc.contains('wrap')) {
          tags.add('2for1 Wrap');
        } else if (desc.contains('main')) {
          tags.add('2for1 Main Item');
        } else {
          tags.add('2for1 Main Item');
        }
        break;
      case 'percentage':
        tags.add('${restaurant.discount.percentage?.toInt()}% Discount');
        break;
      case 'fixed':
        tags.add('£${restaurant.discount.fixedAmount?.toStringAsFixed(0)} Discount');
        break;
    }

    // Add additional free items based on description
    if (desc.contains('dessert')) {
      tags.add('FREE Dessert');
    }
    if (desc.contains('soup')) {
      tags.add('FREE Soup');
    }
    if (desc.contains('drink') || desc.contains('soft drink')) {
      tags.add('FREE Soft Drink');
    }
    if (desc.contains('caipirinha')) {
      tags.add('FREE Caipirinha');
    }
    if (desc.contains('side')) {
      tags.add('FREE Side Dish');
    }

    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearching,
      onPopInvoked: (didPop) {
        if (!didPop && _isSearching) {
          _searchController.clear();
          _searchFocusNode.unfocus();
          setState(() {
            _isSearching = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: NeoTasteColors.background,
        body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRestaurants,
          child: CustomScrollView(
            slivers: [
              // Top Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _isSearching
                      ? // Search Mode - Center search bar
                      Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: NeoTasteColors.textPrimary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                                setState(() {
                                  _isSearching = false;
                                });
                              },
                            ),
                            Expanded(
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _searchController,
                                builder: (context, value, child) {
                                  return TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'Search restaurants...',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: NeoTasteColors.textSecondary,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: NeoTasteColors.textSecondary,
                                        size: 20,
                                      ),
                                      suffixIcon: value.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: NeoTasteColors.textSecondary,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: NeoTasteColors.textPrimary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : // Normal Mode - Location and Search icon
                      Row(
                          children: [
                            // City Selector
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => CitySelectorModal(
                                    selectedCity: _cityName,
                                    onCitySelected: (city) {
                                      setState(() {
                                        _cityName = city;
                                      });
                                      _loadRestaurants();
                                    },
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _cityName,
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: NeoTasteColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: NeoTasteColors.textPrimary,
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
                                color: NeoTasteColors.textPrimary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isSearching = true;
                                });
                                // Request focus after build
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _searchFocusNode.requestFocus();
                                });
                              },
                            ),
                          ],
                        ),
                ),
              ),

              // "Now open and nearby" Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 0, 16),
                  child: Text(
                    'Now open and nearby',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        width: 240,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: NeoTasteColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredRestaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = _filteredRestaurants[index];
                        return _HomeRestaurantCard(
                          restaurant: restaurant,
                          onOfferTags: _getOfferTags,
                          onKmToMiles: _kmToMiles,
                        );
                      },
                    ),
                  ),
                ),

              // "My London list" Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 0, 16),
                  child: Text(
                    'My $_cityName list',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: NeoTasteColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: NeoTasteColors.textDisabled.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 48,
                          color: NeoTasteColors.textDisabled,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nothing saved... yet!',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: NeoTasteColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the heart icon to save the places you want to discover.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: NeoTasteColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // "Top 10 in London" Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 0, 16),
                  child: Row(
                    children: [
                      Text(
                        'Top 10 in $_cityName',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '😋',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        width: 240,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: NeoTasteColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredRestaurants.length > 10 ? 10 : _filteredRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = _filteredRestaurants[index];
                        return _HomeRestaurantCard(
                          restaurant: restaurant,
                          onOfferTags: _getOfferTags,
                          onKmToMiles: _kmToMiles,
                        );
                      },
                    ),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
        ),
      ),
      );
  }
}

/// Home Restaurant Card
class _HomeRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final List<String> Function(Restaurant) onOfferTags;
  final double Function(double) onKmToMiles;

  const _HomeRestaurantCard({
    required this.restaurant,
    required this.onOfferTags,
    required this.onKmToMiles,
  });

  @override
  Widget build(BuildContext context) {
    final offerTags = onOfferTags(restaurant);
    final distanceMiles = onKmToMiles(restaurant.distance);

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
        width: 240,
        margin: const EdgeInsets.only(right: 16),
        decoration: const BoxDecoration(
          color: NeoTasteColors.background,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with AspectRatio 4/3 and border radius on all sides
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: restaurant.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: NeoTasteColors.textDisabled,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: NeoTasteColors.textDisabled,
                    child: const Icon(
                      Icons.restaurant,
                      color: NeoTasteColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            // Content (no border radius)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Restaurant Name
                  Text(
                    restaurant.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Rating, Distance, Cuisine in one row with dot separators
                  Row(
                    children: [
                      // const Icon(
                      //   Icons.star,
                      //   color: Colors.amber,
                      //   size: 14,
                      // ),
                      // const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                      Text(
                        ' (${restaurant.reviewCount})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: NeoTasteColors.textSecondary,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: NeoTasteColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${distanceMiles.toStringAsFixed(2)} mi',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: NeoTasteColors.textSecondary,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: NeoTasteColors.textSecondary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          restaurant.cuisine,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: NeoTasteColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (offerTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    // Offer Chips using Wrap
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: offerTags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
