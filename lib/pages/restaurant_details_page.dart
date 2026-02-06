import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/restaurant.dart';
import '../models/restaurant_detail.dart';
import '../models/review.dart';
import '../models/menu_item.dart';
import '../services/restaurant_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/generic_bottom_sheet.dart';
import 'deals/redeem_offer_modal.dart';
import 'bookings/booking_selection_modal.dart';

/// Restaurant details page - Redesigned
class RestaurantDetailsPage extends StatefulWidget {
  final String slug;

  const RestaurantDetailsPage({super.key, required this.slug});

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  final RestaurantService _restaurantService = RestaurantService();
  RestaurantDetail? _restaurantDetail;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _errorMessage;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurant() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final restaurantDetail = await _restaurantService
          .getRestaurantDetailBySlug(widget.slug);
      setState(() {
        _restaurantDetail = restaurantDetail;
        _isFavorite = restaurantDetail.restaurant.isFavourite;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Convert km to miles
  double _kmToMiles(double km) {
    return km * 0.621371;
  }

  // Get opening hours (using restaurant opening hours or default)
  String _getOpeningHours(Restaurant restaurant) {
    if (restaurant.openingHours.isNotEmpty) {
      // Extract closing time from first opening hour string
      final firstHour = restaurant.openingHours[0];
      if (firstHour.contains('-')) {
        final parts = firstHour.split('-');
        if (parts.length > 1) {
          return 'Open until ${parts[1].trim()}';
        }
      }
      return firstHour;
    }
    return 'Open until 22:00';
  }

  // Get price range from restaurant data
  String _getPriceRange(Restaurant restaurant) {
    final priceRange = restaurant.priceRange ?? 2;
    // Convert price range (1-4) to £ symbols
    return '£' * priceRange;
  }

  // Toggle favorite status
  Future<void> _toggleFavorite() async {
    if (_restaurantDetail == null) return;

    final slug =
        _restaurantDetail!.restaurant.slug ?? _restaurantDetail!.restaurant.id;
    final currentStatus = _isFavorite;

    setState(() {
      _isFavorite = !currentStatus;
    });

    try {
      final newStatus = await _restaurantService.toggleFavourite(
        slug,
        currentStatus,
      );
      if (mounted) {
        setState(() {
          _isFavorite = newStatus;
        });
      }
    } catch (e) {
      // Revert if failed
      if (mounted) {
        setState(() {
          _isFavorite = currentStatus;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _restaurantDetail == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Restaurant Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Failed to load restaurant',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRestaurant,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final restaurant = _restaurantDetail!.restaurant;
    final reviews = _restaurantDetail!.reviews;
    final menuCategories = _restaurantDetail!.menuCategories;
    final distanceMiles = _kmToMiles(restaurant.distance);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        cacheExtent: 500,
        slivers: [
          // Header with full-width image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: isDark ? Colors.black54 : Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: isDark ? Colors.white : Colors.black,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: restaurant.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: const Icon(Icons.restaurant, size: 64),
                    ),
                  ),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Info Card and Content
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -32), // Pull up to overlap
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusXxl),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Info
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xxl + AppSpacing.xxl,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  restaurant.name,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              // Favorite Button
                              IconButton(
                                onPressed: _toggleFavorite,
                                icon: Icon(
                                  _isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _isFavorite
                                      ? Colors.red
                                      : theme.iconTheme.color,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // Details Rows
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                restaurant.cuisine,
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text('•', style: theme.textTheme.bodySmall),
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              Text(
                                '${distanceMiles.toStringAsFixed(1)} mi',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text('•', style: theme.textTheme.bodySmall),
                              Text(
                                _getPriceRange(restaurant),
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text('•', style: theme.textTheme.bodySmall),
                              Text(
                                _getOpeningHours(restaurant),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Action Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showMenuPopup(context, menuCategories),
                                  icon: const Icon(Icons.restaurant_menu),
                                  label: const Text('Menu'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    side: BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final message =
                                        'Check out this deal at ${restaurant.name}!\n\n'
                                        '${restaurant.discount.displayText} - ${restaurant.discount.description}\n\n'
                                        '📍 ${restaurant.address}\n'
                                        'Found on DiscountBuddy';
                                    Share.share(message);
                                  },
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    side: BorderSide(
                                      color: isDark
                                          ? AppColors.dividerDark
                                          : AppColors.dividerLight,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                    foregroundColor: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Offer Card Section
                    if (restaurant.activeDeals.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Text(
                          'Active Offers 📢',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (restaurant.activeDeals.length > 1)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: restaurant.activeDeals.map((deal) {
                              return Container(
                                width: 300,
                                margin: const EdgeInsets.only(right: 12),
                                child: _OfferCard(discount: deal),
                              );
                            }).toList(),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: _OfferCard(discount: restaurant.discount),
                        ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    // Opening Hours
                    if (restaurant.openingSlots.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: _OpeningHoursSection(
                          openingSlots: restaurant.openingSlots,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    // Reviews
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ratings & reviews',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Row(
                                children: List.generate(5, (index) {
                                  final rating = restaurant.rating;
                                  final filled = index < rating.floor();
                                  final halfFilled =
                                      index == rating.floor() &&
                                      rating % 1 >= 0.5;
                                  return Icon(
                                    halfFilled
                                        ? Icons.star_half
                                        : filled
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: AppColors.warning,
                                    size: 24,
                                  );
                                }),
                              ),
                            ],
                          ),
                          Text(
                            '${restaurant.reviewCount} ratings | ${restaurant.reviewCount} reviews',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (reviews.isEmpty)
                            Center(
                              child: Text(
                                'No reviews yet',
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                          else
                            ...reviews.map(
                              (review) => _ReviewItem(review: review),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Location
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Location',
                                style: theme.textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            restaurant.address,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Map Placeholder (RepaintBoundary logic preserved)
                          RepaintBoundary(
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusXl,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.dividerDark
                                      : AppColors.dividerLight,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusXl,
                                ),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                      restaurant.latitude,
                                      restaurant.longitude,
                                    ),
                                    zoom: 15,
                                  ),
                                  onMapCreated: (controller) {
                                    _mapController ??= controller;
                                  },
                                  markers: {
                                    Marker(
                                      markerId: MarkerId(restaurant.id),
                                      position: LatLng(
                                        restaurant.latitude,
                                        restaurant.longitude,
                                      ),
                                    ),
                                  },
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  mapType: MapType.normal,
                                  liteModeEnabled: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Sticky Button (CTA)
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          height: AppSpacing.buttonHeight,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              if (restaurant.requiresBooking) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      BookingSelectionModal(restaurant: restaurant),
                );
              } else {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      RedeemOfferModal(restaurant: restaurant),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Text(
              'Redeem Offer',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMenuPopup(BuildContext context, List<MenuCategory> menuCategories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuPopup(menuCategories: menuCategories),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Discount discount;
  const _OfferCard({required this.discount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            discount.displayText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(discount.description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final Review review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : '?',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: theme.textTheme.titleSmall),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          review.rating.toString(),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Text(review.timeAgo, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (review.comment != null)
            Text(review.comment!, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _OpeningHoursSection extends StatelessWidget {
  final List<OpeningSlot> openingSlots;
  const _OpeningHoursSection({required this.openingSlots});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDay = DateFormat('EEEE').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Opening Hours', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: openingSlots.length,
            itemBuilder: (context, index) {
              final slot = openingSlots[index];
              final isToday =
                  slot.dayName.toLowerCase() == currentDay.toLowerCase();
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.success.withOpacity(0.1)
                      : theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isToday ? AppColors.success : theme.dividerColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slot.dayName.substring(0, 3),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.isClosed ? 'Closed' : slot.openingTime,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (!slot.isClosed)
                      Text(slot.closingTime, style: theme.textTheme.bodySmall),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Menu Popup (Simplified for brevity, assuming existing logic/widgets)
class MenuPopup extends StatelessWidget {
  final List<MenuCategory> menuCategories;
  const MenuPopup({super.key, required this.menuCategories});

  @override
  Widget build(BuildContext context) {
    // Reusing the same structure as before but ensuring Theme usage
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return GenericBottomSheet(
          title: 'Menu',
          expandChild: true,
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: menuCategories.length,
            itemBuilder: (context, index) =>
                _MenuCategoryItem(category: menuCategories[index]),
          ),
        );
      },
    );
  }
}

class _MenuCategoryItem extends StatelessWidget {
  final MenuCategory category;
  const _MenuCategoryItem({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category.name, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        ...category.items.map((item) => _MenuItemCard(item: item)),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.titleMedium),
                if (item.description.isNotEmpty)
                  Text(item.description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text('£${item.price}', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
