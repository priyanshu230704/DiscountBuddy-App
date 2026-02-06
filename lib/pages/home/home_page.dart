import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../restaurant_details_page.dart';
import '../../widgets/city_selector_modal.dart';
import '../../widgets/discount_buddy_card.dart';

/// Home page with feed-style vertical sections
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  final AuthProvider _authProvider = AuthProvider();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  List<Restaurant> _nowOpenRestaurants = [];
  List<Restaurant> _top10Restaurants = [];
  List<Restaurant> _savedRestaurants = [];
  List<Map<String, dynamic>> _cuisineSections = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _cityName = 'London';
  int _cityId = 1;

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
      // For customer role, use the home API endpoint
      if (_authProvider.isCustomer) {
        final homeData = await _restaurantService.getHomeData();

        // Build cuisine map from cuisines array for better cuisine assignment
        final Map<int, String> cuisineMap = {};
        final cuisinesJson = homeData['cuisines'] as List<dynamic>? ?? [];
        for (final cuisineGroup in cuisinesJson) {
          if (cuisineGroup is Map<String, dynamic>) {
            final cuisine = cuisineGroup['cuisine'] as Map<String, dynamic>?;
            final cuisineName = cuisine?['name'] as String? ?? 'Restaurant';
            final restaurants =
                cuisineGroup['restaurants'] as List<dynamic>? ?? [];
            for (final restaurant in restaurants) {
              if (restaurant is Map<String, dynamic>) {
                final restaurantId = restaurant['id'] as int?;
                if (restaurantId != null) {
                  cuisineMap[restaurantId] = cuisineName;
                }
              }
            }
          }
        }

        // Convert API response to Restaurant models
        final nowOpenJson = homeData['now_open'] as List<dynamic>? ?? [];
        final nearbyJson = homeData['nearby'] as List<dynamic>? ?? [];
        final top10Json = homeData['top_10'] as List<dynamic>? ?? [];

        // Combine now_open and nearby for "Now open and nearby" section
        final combinedNearby = [...nowOpenJson, ...nearbyJson];
        final nowOpenRestaurants = combinedNearby
            .map(
              (json) => _restaurantService.convertApiRestaurantToModel(
                json as Map<String, dynamic>,
                cuisineMap: cuisineMap,
              ),
            )
            .toList();

        // Get top 10 restaurants
        final top10Restaurants = top10Json
            .map(
              (json) => _restaurantService.convertApiRestaurantToModel(
                json as Map<String, dynamic>,
                cuisineMap: cuisineMap,
              ),
            )
            .toList();

        // Use all_restaurants for search/filtering
        final allRestaurantsJson =
            homeData['all_restaurants'] as List<dynamic>? ?? [];
        final allRestaurants = allRestaurantsJson
            .map(
              (json) => _restaurantService.convertApiRestaurantToModel(
                json as Map<String, dynamic>,
                cuisineMap: cuisineMap,
              ),
            )
            .toList();

        // Process cuisine sections
        final List<Map<String, dynamic>> cuisineSections = [];
        for (final group in cuisinesJson) {
          if (group is Map<String, dynamic>) {
            final cuisine = group['cuisine'] as Map<String, dynamic>?;
            if (cuisine != null) {
              final restaurantsJson =
                  group['restaurants'] as List<dynamic>? ?? [];
              final restaurants = restaurantsJson
                  .map(
                    (r) => _restaurantService.convertApiRestaurantToModel(
                      r as Map<String, dynamic>,
                      cuisineMap: cuisineMap,
                    ),
                  )
                  .toList();

              cuisineSections.add({
                'id': cuisine['id'],
                'name': cuisine['name'],
                'icon': cuisine['icon'],
                'restaurants': restaurants,
              });
            }
          }
        }

        // Fetch saved restaurants separately
        final savedRestaurants = await _restaurantService.getSavedRestaurants();

        setState(() {
          _nowOpenRestaurants = nowOpenRestaurants;
          _top10Restaurants = top10Restaurants;
          _restaurants = allRestaurants;
          _filteredRestaurants = allRestaurants;
          _savedRestaurants = savedRestaurants;
          _cuisineSections = cuisineSections;
          _isLoading = false;
        });
      } else {
        // Fallback to old method for non-customer roles
        final restaurants = await _restaurantService.getNearbyRestaurants(
          latitude: 51.5074,
          longitude: -0.1278,
        );
        setState(() {
          _restaurants = restaurants;
          _filteredRestaurants = restaurants;
          _nowOpenRestaurants = restaurants;
          _top10Restaurants = restaurants.length > 10
              ? restaurants.sublist(0, 10)
              : restaurants;
          _isLoading = false;
        });
      }
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
        tags.add(
          '£${restaurant.discount.fixedAmount?.toStringAsFixed(0)} Discount',
        );
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

  void _onRestaurantTap(Restaurant restaurant) {
    final slug = restaurant.slug ?? restaurant.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantDetailsPage(slug: slug),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadRestaurants,
            child: CustomScrollView(
              slivers: [
                // Top Header (Search/City)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: _isSearching
                        ? Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: theme.iconTheme.color,
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusLg,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'Search restaurants...',
                                      hintStyle: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        size: 20,
                                        color: theme.iconTheme.color,
                                      ),
                                      suffixIcon:
                                          _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.close,
                                                size: 20,
                                                color: theme.iconTheme.color,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
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
                                          _cityId = city.id;
                                          _cityName = city.name;
                                        });
                                        _loadRestaurants();
                                      },
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      _cityName,
                                      style: theme.textTheme.headlineSmall,
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: theme.iconTheme.color,
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  Icons.search,
                                  color: theme.iconTheme.color,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isSearching = true;
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _searchFocusNode.requestFocus();
                                  });
                                },
                              ),
                            ],
                          ),
                  ),
                ),

                // Explore Cuisines (Horizontal - Keep as chips but styled better)
                if (!_isLoading && _cuisineSections.isNotEmpty && !_isSearching)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Text(
                            'Explore Cuisines',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            itemCount: _cuisineSections.length,
                            itemBuilder: (context, index) {
                              final cuisine = _cuisineSections[index];
                              return _CuisineChip(
                                name: cuisine['name'] ?? '',
                                icon: cuisine['icon'] ?? '🍴',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Sections - Vertical List (Feed)
                if (_isLoading)
                  SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_isSearching)
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final restaurant = _filteredRestaurants[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: DiscountBuddyCard(
                          restaurant: restaurant,
                          offerTags: _getOfferTags(restaurant),
                          distanceText:
                              '${_kmToMiles(restaurant.distance).toStringAsFixed(1)} mi',
                          onTap: () => _onRestaurantTap(restaurant),
                        ),
                      );
                    }, childCount: _filteredRestaurants.length),
                  )
                else ...[
                  // Now Open and Nearby
                  if (_nowOpenRestaurants.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Text(
                          'Now open and nearby',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final restaurant = _nowOpenRestaurants[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: DiscountBuddyCard(
                            restaurant: restaurant,
                            offerTags: _getOfferTags(restaurant),
                            distanceText:
                                '${_kmToMiles(restaurant.distance).toStringAsFixed(1)} mi',
                            onTap: () => _onRestaurantTap(restaurant),
                          ),
                        );
                      }, childCount: _nowOpenRestaurants.length),
                    ),
                  ],

                  // Saved Restaurants
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xxl,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Text(
                        'My $_cityName list',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                  if (_savedRestaurants.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXl,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.dividerDark
                                  : AppColors.dividerLight,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 48,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Nothing saved... yet!',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Tap the heart icon to save the places you want to discover.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // Use a horizontal list for saved (Saved items are usually few, horizontal is fine? Requirement says Avoid horizontal lists for main feed.
                    // But Saved is distinct. I'll make it vertical for consistency with "Feed-style")
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final restaurant = _savedRestaurants[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: DiscountBuddyCard(
                            restaurant: restaurant,
                            offerTags: _getOfferTags(restaurant),
                            distanceText:
                                '${_kmToMiles(restaurant.distance).toStringAsFixed(1)} mi',
                            onTap: () => _onRestaurantTap(restaurant),
                          ),
                        );
                      }, childCount: _savedRestaurants.length),
                    ),

                  // Top 10
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xxl,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Top 10 in $_cityName',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(width: 4),
                          const Text('😋', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final restaurant = _top10Restaurants[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: DiscountBuddyCard(
                          restaurant: restaurant,
                          offerTags: _getOfferTags(restaurant),
                          distanceText:
                              '${_kmToMiles(restaurant.distance).toStringAsFixed(1)} mi',
                          onTap: () => _onRestaurantTap(restaurant),
                        ),
                      );
                    }, childCount: _top10Restaurants.length),
                  ),

                  // Cuisine Sections
                  ..._cuisineSections.map((section) {
                    final restaurants =
                        section['restaurants'] as List<Restaurant>;
                    if (restaurants.isEmpty)
                      return const SliverToBoxAdapter(child: SizedBox.shrink());

                    return SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.xxl,
                              AppSpacing.lg,
                              AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  section['name'] ?? '',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  section['icon'] ?? '',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 2-column grid for cuisine sections
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75, // Adjust as needed
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final restaurant = restaurants[index];
                              return DiscountBuddyCard(
                                restaurant: restaurant,
                                offerTags: _getOfferTags(restaurant),
                                distanceText:
                                    '${_kmToMiles(restaurant.distance).toStringAsFixed(1)} mi',
                                onTap: () => _onRestaurantTap(restaurant),
                              );
                            }, childCount: restaurants.length),
                          ),
                        ),
                      ],
                    );
                  }),
                ],

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ), // Bottom padding for floating nav
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CuisineChip extends StatelessWidget {
  final String name;
  final String icon;

  const _CuisineChip({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              shape: BoxShape.circle,
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
              border: Border.all(
                color: isDark ? AppColors.dividerDark : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            name,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
