import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../../services/merchant_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_gradient_button.dart';
import '../../components/layout.dart';
import '../../components/app_app_bar.dart';
import 'add_restaurant_page.dart';
import 'merchant_menu_page.dart';

class MerchantRestaurantsPage extends StatefulWidget {
  final bool selectMenuMode;

  const MerchantRestaurantsPage({
    super.key,
    this.selectMenuMode = false,
  });

  @override
  State<MerchantRestaurantsPage> createState() =>
      _MerchantRestaurantsPageState();
}

class _MerchantRestaurantsPageState extends State<MerchantRestaurantsPage> {
  final MerchantService _merchantService = MerchantService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _filteredRestaurants = [];
  bool _isLoading = true;

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

  Future<void> _loadRestaurants() async {
    try {
      if (mounted) setState(() => _isLoading = true);
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterRestaurants(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRestaurants = _restaurants;
      } else {
        _filteredRestaurants = _restaurants.where((r) {
          final name = (r['name'] as String?)?.toLowerCase() ?? '';
          final address = (r['address'] as String?)?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || address.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: widget.selectMenuMode ? 'Select Restaurant' : 'Restaurants',
        backgroundColor: Colors.transparent,
        actions: widget.selectMenuMode
            ? null
            : [
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.merchantIndigo,
                  ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterRestaurants,
                      decoration: InputDecoration(
                        hintText: "Search restaurants...",
                        hintStyle: AppTypography.bodySmall.copyWith(fontSize: 14),
                        border: InputBorder.none,
                      ),
                      style: AppTypography.body.copyWith(fontSize: 14),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        _filterRestaurants('');
                      },
                    ),
                ],
              ),
            ),
          ),
          if (!_isLoading && _filteredRestaurants.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
              child: Text(
                '${_filteredRestaurants.length} Restaurant${_filteredRestaurants.length == 1 ? '' : 's'}',
                style: AppTypography.title.copyWith(fontSize: 18),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading restaurants...')
                : _filteredRestaurants.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadRestaurants,
                    color: AppColors.merchantIndigo,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.sm,
                        AppSpacing.xl,
                        AppSpacing.xxxl,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
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
        final fullRestaurant = await _merchantService.getRestaurantDetail(id);
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
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.store_mall_directory_rounded,
      title: 'No restaurants found',
      message: _searchController.text.isNotEmpty
          ? 'Try adjusting your search query.'
          : 'Your linked restaurants will appear here.',
      primaryActionLabel: widget.selectMenuMode || _searchController.text.isNotEmpty ? null : 'Add restaurant',
      onPrimaryAction: widget.selectMenuMode || _searchController.text.isNotEmpty
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
              color: AppColors.merchantIndigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.merchantIndigo,
              size: 24,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.location_on,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        restaurant['address'] as String? ?? 'No address provided',
                        style: AppTypography.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDisabled,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
