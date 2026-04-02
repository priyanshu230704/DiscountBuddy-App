import 'dart:async';
import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import '../services/location_service.dart';
import '../widgets/restaurant_card.dart';
import 'restaurant_details_page.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

/// Search/Discover page for finding restaurants
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = false;
  String _selectedCuisine = 'All';
  double? _userLat;
  double? _userLon;
  List<Map<String, dynamic>> _cuisines = [];
  int? _selectedCuisineId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadLocationAndRestaurants(),
      _loadCuisines(),
    ]);
  }

  Future<void> _loadCuisines() async {
    final cuisines = await _restaurantService.getCuisines();
    if (mounted) {
      setState(() {
        _cuisines = cuisines;
      });
    }
  }

  Future<void> _loadLocationAndRestaurants() async {
    try {
      final position = await _locationService.getCurrentLocation();
      _userLat = position.latitude;
      _userLon = position.longitude;
    } catch (e) {
      debugPrint('Error getting location in SearchPage: $e');
    }
    await _loadRestaurants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final query = _searchController.text.trim();
      List<Restaurant> results;

      if (query.isNotEmpty) {
        results = await _restaurantService.searchRestaurants(
          query: query,
          latitude: _userLat,
          longitude: _userLon,
        );
      } else {
        results = await _restaurantService.getRestaurants(
          latitude: _userLat,
          longitude: _userLon,
        );
      }

      if (mounted) {
        setState(() {
          _restaurants = results;
          _filterRestaurants(); // Still apply local cuisine filter if needed
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Timer? _searchDebounce;
  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadRestaurants();
    });
  }

  void _filterRestaurants() {
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        if (_selectedCuisineId == null) return true;
        return restaurant.cuisines.any((c) => c.id == _selectedCuisineId);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
          // Search App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Discover',
                style: AppTypography.title.copyWith(color: AppColors.textPrimary),
              ),
              centerTitle: false,
            ),
          ),
          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.xLarge,
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppShadows.card,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search restaurants...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.xLarge,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          // Cuisine Filter Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                itemCount: _cuisines.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = _selectedCuisineId == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCuisineId = null;
                            _filterRestaurants();
                          });
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : AppColors.cardBorder,
                          ),
                        ),
                        labelStyle: AppTypography.body.copyWith(
                          color: isSelected ? AppColors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  } else {
                    final cuisine = _cuisines[index - 1];
                    final cuisineId = cuisine['id'];
                    final isSelected = cuisineId == _selectedCuisineId;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: Text(cuisine['name'] as String),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCuisineId = selected ? cuisineId : null;
                            _filterRestaurants();
                          });
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : AppColors.cardBorder,
                          ),
                        ),
                        labelStyle: AppTypography.body.copyWith(
                          color: isSelected ? AppColors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          // Results Count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                '${_filteredRestaurants.length} restaurants found',
                style: AppTypography.bodySmall,
              ),
            ),
          ),
          // Restaurants List
          if (_isLoading)
            const SliverFillRemaining(
              child: LoadingWidget(message: 'Loading restaurants...'),
            )
          else if (_filteredRestaurants.isEmpty)
            SliverFillRemaining(
              child: EmptyStateWidget(
                icon: Icons.search_off,
                title: 'No restaurants found',
                message: 'Try a different search term',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final restaurant = _filteredRestaurants[index];
                  return RestaurantCard(
                    restaurant: restaurant,
                    userLat: _userLat,
                    userLon: _userLon,
                    onTap: () {
                      final slug = restaurant.slug ?? restaurant.id;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantDetailsPage(
                            slug: slug,
                            latitude: _userLat,
                            longitude: _userLon,
                          ),
                        ),
                      );
                    },
                  );
                }, childCount: _filteredRestaurants.length),
              ),
            ),
          ],
        ),
    );
  }
}
