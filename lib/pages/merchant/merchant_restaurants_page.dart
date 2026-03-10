import 'package:discount_buddy/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/merchant_service.dart';
import '../../widgets/skeleton_loader.dart';
import 'add_restaurant_page.dart';
import 'merchant_menu_page.dart';

/// Merchant Restaurants Management Page
class MerchantRestaurantsPage extends StatefulWidget {
  final bool selectMenuMode;

  const MerchantRestaurantsPage({super.key, this.selectMenuMode = false});

  @override
  State<MerchantRestaurantsPage> createState() =>
      _MerchantRestaurantsPageState();
}

class _MerchantRestaurantsPageState extends State<MerchantRestaurantsPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _filteredRestaurants = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isFetching = false;

  Future<void> _loadRestaurants() async {
    if (_isFetching) return;

    try {
      setState(() {
        _isLoading = true;
        _isFetching = true;
      });
      final restaurants = await _merchantService.getMerchantRestaurants();
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          _filteredRestaurants = restaurants;
          _isLoading = false;
        });
        _filterRestaurants(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load restaurants: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        _isFetching = false;
      }
    }
  }

  void _filterRestaurants(String query) {
    if (query.isEmpty) {
      setState(() => _filteredRestaurants = _restaurants);
      return;
    }
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final name = (restaurant['name'] as String? ?? '').toLowerCase();
        final city = (restaurant['city'] as Map?)?['name'] as String? ?? '';
        return name.contains(query.toLowerCase()) ||
            city.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.selectMenuMode ? 'Select Restaurant' : 'Restaurants',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: widget.selectMenuMode
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddRestaurantPage(),
                      ),
                    ).then((_) => _loadRestaurants());
                  },
                ),
              ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterRestaurants,
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                hintStyle: GoogleFonts.inter(color: AppColors.textDisabled),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredRestaurants.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadRestaurants,
                    color: AppColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: _filteredRestaurants.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final restaurant = _filteredRestaurants[index];
                        return _RestaurantCard(
                          restaurant: restaurant,
                          onTap: () => _handleRestaurantTap(restaurant),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _handleRestaurantTap(Map<String, dynamic> restaurant) async {
    final restaurantId = restaurant['id'];
    final id = restaurantId is int
        ? restaurantId
        : int.tryParse(restaurantId.toString());

    if (id == null) return;

    if (widget.selectMenuMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MerchantMenuPage(
            restaurantId: id,
            restaurantName: restaurant['name'] ?? 'Restaurant',
          ),
        ),
      );
    } else {
      try {
        final fullRestaurant = await _merchantService.getRestaurantDetails(id);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddRestaurantPage(restaurant: fullRestaurant),
            ),
          ).then((refresh) {
            if (refresh == true) {
              _loadRestaurants();
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load restaurant: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SkeletonLoader(
          height: 100,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory_rounded,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'No restaurants found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (!widget.selectMenuMode) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddRestaurantPage(),
                  ),
                ).then((_) => _loadRestaurants());
              },
              child: Text(
                'Add Restaurant',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.textDisabled.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant['name'] as String? ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurant['address'] as String? ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
