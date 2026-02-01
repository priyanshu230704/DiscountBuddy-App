import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/loading_widget.dart';
import 'restaurant_details_page.dart';

/// Search/Discover page for finding restaurants
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

// Local constants for search page
class _SearchConstants {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double radiusMedium = 12.0;
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
        final matchesSearch = restaurant.name.toLowerCase().contains(query) ||
            restaurant.cuisine.toLowerCase().contains(query) ||
            restaurant.address.toLowerCase().contains(query);
        final matchesCuisine = _selectedCuisine == 'All' ||
            restaurant.cuisine == _selectedCuisine;
        return matchesSearch && matchesCuisine;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Search App Bar
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF1A73E8),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Discover',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A73E8),
                      const Color(0xFF1A73E8).withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(_SearchConstants.paddingMedium),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search restaurants...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_SearchConstants.radiusMedium),
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
                  horizontal: _SearchConstants.paddingMedium,
                ),
                itemCount: _cuisines.length,
                itemBuilder: (context, index) {
                  final cuisine = _cuisines[index];
                  final isSelected = cuisine == _selectedCuisine;
                  return Padding(
                    padding: const EdgeInsets.only(right: _SearchConstants.paddingSmall),
                    child: FilterChip(
                      label: Text(cuisine),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCuisine = cuisine;
                          _filterRestaurants();
                        });
                      },
                      selectedColor: const Color(0xFF1A73E8),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
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
                horizontal: _SearchConstants.paddingMedium,
                vertical: _SearchConstants.paddingSmall,
              ),
              child: Text(
                '${_filteredRestaurants.length} restaurants found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No restaurants found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search term',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: _SearchConstants.paddingMedium,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final restaurant = _filteredRestaurants[index];
                    return RestaurantCard(
                      restaurant: restaurant,
                      onTap: () {
                        final slug = restaurant.slug ?? restaurant.id;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestaurantDetailsPage(slug: slug),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _filteredRestaurants.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

