import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discount_buddy/core/theme/app_design.dart';
import 'package:get/get.dart';

import 'package:discount_buddy/features/restaurants/data/restaurant_provider.dart';
import 'package:discount_buddy/features/nearby/data/nearby_provider.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'package:discount_buddy/features/restaurants/widgets/restaurant_card.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/widgets/loading_widget.dart';
import 'package:discount_buddy/widgets/empty_state_widget.dart';

/// Search/Discover page for finding restaurants
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  double? _userLat;
  double? _userLon;
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
    if (mounted) {
      await context.read<RestaurantProvider>().getCuisines();
    }
  }

  Future<void> _loadLocationAndRestaurants() async {
    try {
      final nearbyProvider = context.read<NearbyProvider>();
      final position = await nearbyProvider.getCurrentPosition(requestPermissionIfDenied: false);
      if (position != null) {
        _userLat = position.latitude;
        _userLon = position.longitude;
      }
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
    try {
      final query = _searchController.text.trim();

      if (query.isNotEmpty) {
        await context.read<RestaurantProvider>().searchRestaurants(
          query: query,
          latitude: _userLat,
          longitude: _userLon,
        );
      } else {
        await context.read<RestaurantProvider>().getRestaurants(
          latitude: _userLat,
          longitude: _userLon,
        );
      }
    } catch (e) {
      debugPrint('Error loading restaurants: $e');
    }
  }

  Timer? _searchDebounce;
  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadRestaurants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<RestaurantProvider>(
        builder: (context, restaurantProvider, _) {
          final restaurants = restaurantProvider.restaurants;
          final cuisines = restaurantProvider.cuisines;
          final filteredRestaurants = restaurants.where((restaurant) {
            if (_selectedCuisineId == null) return true;
            return restaurant.cuisines.any((c) => c.id == _selectedCuisineId);
          }).toList();

          return CustomScrollView(
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: cuisines.length + 1,
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
                              });
                            },
                          ),
                        );
                      }
                      final cuisine = cuisines[index - 1];
                      final cuisineId = cuisine['id'] as int?;
                      final cuisineName = cuisine['name'] as String? ?? 'Unknown';
                      final isSelected = _selectedCuisineId == cuisineId;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(cuisineName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCuisineId = selected ? cuisineId : null;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Restaurants List
              if (restaurantProvider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: LoadingWidget(message: 'Loading restaurants...'),
                  ),
                )
              else if (filteredRestaurants.isEmpty)
                const SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'No restaurants found',
                    message: 'Try searching for different cuisines or locations',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return RestaurantCard(
                          restaurant: filteredRestaurants[index],
                          onTap: () {
                            Get.toNamed(
                              AppRoutes.restaurantDetails,
                              arguments: filteredRestaurants[index].slug,
                            );
                          },
                        );
                      },
                      childCount: filteredRestaurants.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
