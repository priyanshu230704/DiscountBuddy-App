import 'package:discount_buddy/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/restaurant.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import '../utils/distance_utils.dart';

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

  static const double _spacing = 8.0;
  static const double _radius = 14.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: _spacing * 2),
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
              // Hero Image with Badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(_radius),
                    ),
                    child: restaurant.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: restaurant.imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 180,
                              color: AppColors.background,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 180,
                              color: AppColors.background,
                              child: Icon(
                                Icons.restaurant,
                                size: 48,
                                color: AppColors.textDisabled,
                              ),
                            ),
                          )
                        : Container(
                            height: 180,
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
                    top: _spacing * 1.5,
                    right: _spacing * 1.5,
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
                          size: 20,
                        ),
                        onPressed: () {},
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  // Discount Badge
                  if (restaurant.discount.type != 'none' && restaurant.discount.displayText.isNotEmpty)
                    Positioned(
                      bottom: _spacing * 1.5,
                      left: _spacing * 1.5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _spacing * 1.5,
                          vertical: _spacing,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.discount, // Orange discount badge
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          restaurant.discount.displayText,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  // Distance Badge
                  Positioned(
                    top: _spacing * 1.5,
                    left: _spacing * 1.5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _spacing * 1.5,
                        vertical: _spacing,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 14,
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
                            style: AppFonts.bodyStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Content Area
              Padding(
                padding: const EdgeInsets.all(_spacing * 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Rating Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: AppFonts.bodyStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB100),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: AppFonts.bodyStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                ' (${restaurant.reviewCount})',
                                style: AppFonts.bodyStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _spacing * 1.5),

                    // Details Row
                    Row(
                      children: [
                        _buildDetailChip(
                          Icons.restaurant_menu,
                          restaurant.cuisine,
                        ),
                        const SizedBox(width: _spacing * 2),
                        // Safe availability check
                        _buildDetailChip(
                          Icons.calendar_today,
                          restaurant.discount.validDays.isNotEmpty
                              ? restaurant.discount.validDays.join(', ')
                              : 'Mon - Sun',
                        ),
                      ],
                    ),
                    const SizedBox(height: _spacing * 1.5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            restaurant.address,
                            style: AppFonts.bodyStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
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
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppFonts.bodyStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
