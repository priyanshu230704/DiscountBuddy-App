import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import 'package:discount_buddy/components/layout.dart' hide LoadingWidget;
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
  final TextEditingController _searchController = TextEditingController();
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = false;
  String _selectedCuisine = 'All';

  final List<String> _cuisines = [
    'All',
    'Italian',
    'American',
    'Fast Food',
    'Chinese',
    'Indian',
    'Mexican',
    'Thai',
  ];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _searchController.addListener(_onSearchChanged);
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

  void _onSearchChanged() {
    _filterRestaurants();
  }

  void _filterRestaurants() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final matchesSearch =
            restaurant.name.toLowerCase().contains(query) ||
            restaurant.cuisine.toLowerCase().contains(query) ||
            restaurant.address.toLowerCase().contains(query);
        final matchesCuisine =
            _selectedCuisine == 'All' || restaurant.cuisine == _selectedCuisine;
        return matchesSearch && matchesCuisine;
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
                itemCount: _cuisines.length,
                itemBuilder: (context, index) {
                  final cuisine = _cuisines[index];
                  final isSelected = cuisine == _selectedCuisine;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(cuisine),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCuisine = cuisine;
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
                    onTap: () {
                      final slug = restaurant.slug ?? restaurant.id;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RestaurantDetailsPage(slug: slug),
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
