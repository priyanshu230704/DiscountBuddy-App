import 'package:cached_network_image/cached_network_image.dart';
import 'package:discount_buddy/core/theme/app_design.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:discount_buddy/features/restaurants/models/restaurant.dart';
import 'package:discount_buddy/features/nearby/data/location_service.dart';
import 'package:discount_buddy/features/restaurants/data/restaurant_service.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'package:discount_buddy/core/utils/distance_utils.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/widgets/loading_widget.dart';
import 'package:discount_buddy/components/app_app_bar.dart';

class SavedRestaurantsPage extends StatefulWidget {
  const SavedRestaurantsPage({super.key});

  @override
  State<SavedRestaurantsPage> createState() => _SavedRestaurantsPageState();
}

class _SavedRestaurantsPageState extends State<SavedRestaurantsPage> {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  List<Restaurant> _savedRestaurants = [];
  bool _isLoading = true;
  double? _userLat;
  double? _userLon;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    setState(() => _isLoading = true);
    try {
      // Get location for pinpoint distance
      try {
        final position = await _locationService.getCurrentLocation();
        _userLat = position.latitude;
        _userLon = position.longitude;
      } catch (e) {
        debugPrint('Location unavailable for saved restaurants: $e');
      }

      // Fetch saved restaurants
      final restaurants = await _restaurantService.getSavedRestaurants(
        latitude: _userLat,
        longitude: _userLon,
      );

      if (mounted) {
        setState(() {
          _savedRestaurants = restaurants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load saved restaurants: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Saved Restaurants',
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading favorites...')
          : _savedRestaurants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      Text(
                        'No saved restaurants yet',
                        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSaved,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _savedRestaurants.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final restaurant = _savedRestaurants[index];
                      return _SavedRestaurantTile(
                        restaurant: restaurant,
                        userLat: _userLat,
                        userLon: _userLon,
                        onToggleFavorite: () async {
                          await _restaurantService.toggleFavourite(
                            restaurant.slug ?? restaurant.id,
                            restaurant.isFavourite,
                          );
                          _loadSaved();
                        },
                      );
                    },
                  ),
            ),
    );
  }
}

class _SavedRestaurantTile extends StatelessWidget {
  final Restaurant restaurant;
  final double? userLat;
  final double? userLon;
  final VoidCallback onToggleFavorite;

  const _SavedRestaurantTile({
    required this.restaurant,
    required this.onToggleFavorite,
    this.userLat,
    this.userLon,
  });

  Color _occupancyColor(String? occupancy) {
    switch (occupancy) {
      case 'very_busy':
        return const Color(0xFFEF4444);
      case 'moderately_busy':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _occupancyLabel(String? occupancy) {
    switch (occupancy) {
      case 'very_busy':
        return 'Very Busy';
      case 'moderately_busy':
        return 'Moderate';
      default:
        return 'Less Busy';
    }
  }

  @override
  Widget build(BuildContext context) {
    final miles = DistanceUtils.bestMiles(
      userLat: userLat,
      userLon: userLon,
      restaurantLat: restaurant.latitude,
      restaurantLon: restaurant.longitude,
      distanceMilesFromApi: restaurant.distanceMiles,
      distanceKmFromApi: restaurant.distance,
    );
    final hasImage = restaurant.imageUrl.isNotEmpty;
    final deals = restaurant.activeDeals.where((d) => d.type != 'none').toList();

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.restaurantDetails,
          arguments: {
            'slug': restaurant.id,
            'latitude': userLat,
            'longitude': userLon,
          },
        );
      },
      child: Container(
        width: double.infinity,
        height: 188,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 110,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: restaurant.imageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: Color(0xFFD1D5DB),
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: Color(0xFFD1D5DB),
                            size: 40,
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                if (miles != null)
                  Positioned(
                    bottom: 10,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            DistanceUtils.formatMiles(miles),
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (deals.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                deals.first.displayText.toUpperCase(),
                                style: AppTypography.title.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.flash_on, color: Colors.white, size: 12),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            (deals.first.shortDescription != null &&
                                    deals.first.shortDescription!.isNotEmpty)
                                ? deals.first.shortDescription!
                                : "Save today",
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      // Favorite Toggle
                      GestureDetector(
                        onTap: onToggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Color(0xFFF97316),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Occupancy
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                color: _occupancyColor(restaurant.occupancy), size: 8),
                            const SizedBox(width: 5),
                            Text(
                              _occupancyLabel(restaurant.occupancy),
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (restaurant.rating > 0)
                  Positioned(
                    bottom: 10,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
                          const SizedBox(width: 3),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 3, 8, 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            restaurant.name,
                            style: AppTypography.title.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (restaurant.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              restaurant.description.trim(),
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                color: const Color(0xFF6B7280),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (restaurant.cuisine.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              restaurant.cuisine,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9CA3AF),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_offer_outlined,
                                    color: Color(0xFF059669), size: 9),
                                const SizedBox(width: 3),
                                Text(
                                  "££ • Great value",
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppGradientButton(
                          onPressed: () {
                            Get.toNamed(
                              AppRoutes.restaurantDetails,
                              arguments: {
                                'slug': restaurant.id,
                                'latitude': userLat,
                                'longitude': userLon,
                              },
                            );
                          },
                          height: 32,
                          width: 80,
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: Colors.white, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                'Reserve',
                                style: AppTypography.button.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
