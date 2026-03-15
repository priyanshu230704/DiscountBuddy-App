import 'package:flutter/material.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/design/app_spacing.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:discount_buddy/components/layout.dart';
import 'package:discount_buddy/components/inputs.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
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
      appBar: AppAppBar(
        titleText: widget.selectMenuMode ? 'Select restaurant' : 'Restaurants',
        centerTitle: true,
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              onChanged: _filterRestaurants,
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                hintStyle: AppTypography.bodySmall,
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      itemCount: _filteredRestaurants.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),
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
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: SkeletonLoader(
          height: 100,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.store_mall_directory_rounded,
      title: 'No restaurants found',
      message: 'Your linked restaurants will appear here.',
      primaryActionLabel: widget.selectMenuMode ? null : 'Add restaurant',
      onPrimaryAction: widget.selectMenuMode
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRestaurantPage(),
                ),
              ).then((_) => _loadRestaurants());
            },
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant['name'] as String? ?? 'Unknown',
                  style: AppTypography.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        restaurant['address'] as String? ?? '',
                        style: AppTypography.bodySmall,
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
    );
  }
}
