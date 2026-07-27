import 'package:discount_buddy/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant.dart';
import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/core/utils/distance_utils.dart';

/// Premium, minimal Restaurant card widget
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;
  final double? userLat;
  final double? userLon;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.onTap,
    this.userLat,
    this.userLon,
  });

  static const double _radius = 14.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate width to satisfy: 2 full cards + 5-10% (0.1) of next card
    // Formula: list margin horizontal (16) + card1(W) + gap(12) + card2(W) + gap(12) + card3(0.1*W) = screenWidth
    // 16 + 2.1W + 24 = screenWidth  =>  2.1W + 40 = screenWidth
    // Cards must not resize dynamically internally but must maintain this proportion across devices.
    final cardWidth = (screenWidth - 40) / 2.1;

    return Container(
      width: cardWidth,
      height: 230,
      margin: const EdgeInsets.only(right: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image with Badges (140px fixed)
              SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(_radius),
                      ),
                      child: restaurant.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: restaurant.imageUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 140,
                                color: AppColors.background,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 140,
                                color: AppColors.background,
                                child: Icon(
                                  Icons.restaurant,
                                  size: 48,
                                  color: AppColors.textDisabled,
                                ),
                              ),
                            )
                          : Container(
                              height: 140,
                              width: double.infinity,
                              color: AppColors.background,
                              child: Icon(
                                Icons.restaurant,
                                size: 48,
                                color: AppColors.textDisabled,
                              ),
                            ),
                    ),
                    // Bookmark Icon
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            restaurant.isFavourite ? Icons.favorite : Icons.favorite_border,
                            color: restaurant.isFavourite ? Colors.orange : AppColors.textPrimary,
                            size: 16,
                          ),
                          onPressed: () {},
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    // Discount Badge
                    if (restaurant.discount.type != 'none' && restaurant.discount.displayText.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.discount, // Orange discount badge
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            restaurant.discount.displayText,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    // Loyalty Card Badge
                    if (restaurant.loyaltyCardEnabled)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.card_membership_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "LOYALTY",
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 8,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Distance Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              () {
                                final miles = DistanceUtils.bestMiles(
                                  userLat: userLat,
                                  userLon: userLon,
                                  restaurantLat: restaurant.latitude,
                                  restaurantLon: restaurant.longitude,
                                  distanceMilesFromApi: restaurant.distanceMiles,
                                  distanceKmFromApi: restaurant.distance,
                                );
                                return DistanceUtils.formatMiles(miles);
                              }(),
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content Area (90px fixed)
              SizedBox(
                height: 90,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name & Rating Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: AppTypography.title.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB100),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  restaurant.rating.toStringAsFixed(1),
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Details Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailChip(
                              Icons.restaurant_menu,
                              restaurant.cuisine,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildDetailChip(
                              Icons.calendar_today,
                              restaurant.discount.validDays.isNotEmpty
                                  ? restaurant.discount.validDays.join(', ')
                                  : 'Mon-Sun',
                            ),
                          ),
                        ],
                      ),

                      if (restaurant.description.trim().isNotEmpty)
                        Text(
                          restaurant.description.trim(),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.2,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
