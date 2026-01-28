import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/restaurant.dart';
import '../models/restaurant_detail.dart';
import '../models/review.dart';
import '../models/menu_item.dart';
import '../services/restaurant_service.dart';
import '../providers/theme_provider.dart';
import 'deals/redeem_offer_modal.dart';

/// Restaurant details page - NeoTaste style
class RestaurantDetailsPage extends StatefulWidget {
  final String slug;

  const RestaurantDetailsPage({
    super.key,
    required this.slug,
  });

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  final RestaurantService _restaurantService = RestaurantService();
  RestaurantDetail? _restaurantDetail;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final restaurantDetail = await _restaurantService.getRestaurantDetailBySlug(widget.slug);
      setState(() {
        _restaurantDetail = restaurantDetail;
        _isFavorite = false; // You can load this from API if available
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: NeoTasteColors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _restaurantDetail == null) {
      return Scaffold(
        backgroundColor: NeoTasteColors.white,
        appBar: AppBar(
          title: const Text('Restaurant Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: NeoTasteColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Failed to load restaurant',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: NeoTasteColors.textSecondary,
                ),
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
      backgroundColor: NeoTasteColors.white,
      body: CustomScrollView(
        slivers: [
          // Header with full-width image and gradient
          SliverAppBar(
            expandedHeight: 300,
            pinned: false,
            backgroundColor: NeoTasteColors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NeoTasteColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: NeoTasteColors.textPrimary),
                onPressed: () => Navigator.pop(context),
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
                      color: NeoTasteColors.textDisabled,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: NeoTasteColors.textDisabled,
                      child: const Icon(Icons.restaurant, size: 64),
                    ),
                  ),
                  // White gradient fade at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            NeoTasteColors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Restaurant Info Section
          SliverToBoxAdapter(
            child: Container(
              color: NeoTasteColors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Name
                  Text(
                    restaurant.name,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Details Rows
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Cuisine and Location
                      Row(
                        children: [
                          Text(
                            restaurant.cuisine,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: NeoTasteColors.textPrimary,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 14,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: NeoTasteColors.textDisabled,
                          ),
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: NeoTasteColors.textPrimary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${restaurant.address.split(',').first} (${distanceMiles.toStringAsFixed(2)} mi)',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: NeoTasteColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Row 2: Price and Timing
                      Row(
                        children: [
                          Text(
                            _getPriceRange(restaurant),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: NeoTasteColors.textPrimary,
                            ),
                          ),
                          Text(
                            ' ${_getOpeningHours(restaurant)}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: NeoTasteColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      // Menu Button
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _showMenuPopup(context, menuCategories);
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.menu,
                                    color: NeoTasteColors.textPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Menu',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: NeoTasteColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Favorite Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: NeoTasteColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NeoTasteColors.textDisabled.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                              });
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : NeoTasteColors.textPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Share Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: NeoTasteColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NeoTasteColors.textDisabled.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // Share restaurant
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: const Icon(
                              Icons.share,
                              color: NeoTasteColors.textPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Offer Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _OfferCard(
                discount: restaurant.discount,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Reviews Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ratings & reviews',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Overall Rating
                  Row(
                    children: [
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Stars
                      Row(
                        children: List.generate(5, (index) {
                          final rating = restaurant.rating;
                          final filled = index < rating.floor();
                          final halfFilled = index == rating.floor() && rating % 1 >= 0.5;
                          return Icon(
                            halfFilled
                                ? Icons.star_half
                                : filled
                                    ? Icons.star
                                    : Icons.star_border,
                            color: Colors.green,
                            size: 24,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${restaurant.reviewCount} ratings | ${restaurant.reviewCount} reviews',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: NeoTasteColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Individual Reviews
                  if (reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No reviews yet',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: NeoTasteColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...reviews.map((review) => _ReviewItem(review: review)),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Location Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: NeoTasteColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant.address,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                  if (restaurant.postcode != null && restaurant.postcode!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      restaurant.postcode!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: NeoTasteColors.textPrimary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Restaurant Details Section
                  if (restaurant.phoneNumber.isNotEmpty ||
                      restaurant.email != null ||
                      restaurant.website.isNotEmpty) ...[
                    const Divider(height: 24),
                    // Phone
                    if (restaurant.phoneNumber.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              color: NeoTasteColors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                restaurant.phoneNumber,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: NeoTasteColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Email
                    if (restaurant.email != null && restaurant.email!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.email,
                              color: NeoTasteColors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                restaurant.email!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: NeoTasteColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Website
                    if (restaurant.website.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.language,
                              color: NeoTasteColors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Open website URL
                                },
                                child: Text(
                                  restaurant.website,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),
                  // Map
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: NeoTasteColors.textDisabled.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            restaurant.latitude,
                            restaurant.longitude,
                          ),
                          zoom: 15,
                        ),
                        onMapCreated: (controller) {
                          // Map controller initialized
                        },
                        markers: {
                          Marker(
                            markerId: MarkerId(restaurant.id),
                            position: LatLng(
                              restaurant.latitude,
                              restaurant.longitude,
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen,
                            ),
                          ),
                        },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapType: MapType.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),

      // Bottom Sticky Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeoTasteColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => RedeemOfferModal(
                  restaurant: restaurant,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: NeoTasteColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Redeem Offer',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Show menu popup
  void _showMenuPopup(BuildContext context, List<MenuCategory> menuCategories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuPopup(menuCategories: menuCategories),
    );
  }
}

/// Review Item Widget
class _ReviewItem extends StatelessWidget {
  final Review review;

  const _ReviewItem({required this.review});

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(review.userName),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: NeoTasteColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Review Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    review.userName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rating and Time
                  Row(
                    children: [
                      // Stars
                      Row(
                        children: List.generate(5, (index) {
                          final rating = review.rating.toDouble();
                          final filled = index < rating.floor();
                          final halfFilled = index == rating.floor() && rating % 1 >= 0.5;
                          return Icon(
                            halfFilled
                                ? Icons.star_half
                                : filled
                                    ? Icons.star
                                    : Icons.star_border,
                            color: Colors.green,
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        review.timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: NeoTasteColors.textSecondary,
                        ),
                      ),
                      if (review.isVerified) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: NeoTasteColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: NeoTasteColors.white,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: NeoTasteColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (review.comment != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      review.comment!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: NeoTasteColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Offer Card Widget
class _OfferCard extends StatelessWidget {
  final Discount discount;

  const _OfferCard({required this.discount});

  String _getOfferTitle() {
    switch (discount.type) {
      case '2for1':
        return '2for1 Drink';
      case 'percentage':
        return '${discount.percentage?.toInt()}% Discount';
      case 'fixed':
        return '£${discount.fixedAmount?.toStringAsFixed(0)} Discount';
      default:
        return discount.displayText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Info Icon
          Row(
            children: [
              Expanded(
                child: Text(
                  _getOfferTitle(),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NeoTasteColors.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: NeoTasteColors.textSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: NeoTasteColors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OfferChip(
                icon: Icons.card_giftcard,
                text: '~£11 benefit',
              ),
              _OfferChip(
                icon: Icons.autorenew,
                text: '30 days',
              ),
              _OfferChip(
                icon: Icons.location_on,
                text: 'On-site',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            discount.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: NeoTasteColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Offer Chip Widget
class _OfferChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OfferChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NeoTasteColors.textSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: NeoTasteColors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: NeoTasteColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu Popup Widget - Bottom Sheet
class MenuPopup extends StatelessWidget {
  final List<MenuCategory> menuCategories;

  const MenuPopup({super.key, required this.menuCategories});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: NeoTasteColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: NeoTasteColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Menu',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: NeoTasteColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: NeoTasteColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Menu Categories
              Expanded(
                child: menuCategories.isEmpty
                    ? Center(
                        child: Text(
                          'No menu available',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: NeoTasteColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: menuCategories.length,
                        itemBuilder: (context, categoryIndex) {
                          final category = menuCategories[categoryIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Header
                              Padding(
                                padding: EdgeInsets.only(bottom: 12, top: categoryIndex > 0 ? 24 : 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: NeoTasteColors.textPrimary,
                                      ),
                                    ),
                                    if (category.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        category.description,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: NeoTasteColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Menu Items
                              ...category.items.map((item) => _MenuItemCard(item: item)),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Menu Item Card Widget
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeoTasteColors.textDisabled.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Item Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name
              Padding(
                padding: const EdgeInsets.only(right: 40), // Space for symbol
                child: Text(
                  item.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NeoTasteColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Description
              if (item.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 40), // Space for symbol
                  child: Text(
                    item.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: NeoTasteColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Tags and Price Row
              Row(
                children: [
                  // Dietary Tags
                  if (item.isVegan)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'VG',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  if (item.isGlutenFree)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'GF',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Price
                  Text(
                    '£${item.price}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Availability
              if (!item.isAvailable)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Currently unavailable',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          // Vegetarian Symbol at top right
          Positioned(
            top: 0,
            right: 0,
            child: _VegetarianSymbol(isVegetarian: item.isVegetarian),
          ),
        ],
      ),
    );
  }
}

/// Vegetarian Symbol Widget - Green circle inside green square (like packaging symbol)
class _VegetarianSymbol extends StatelessWidget {
  final bool isVegetarian;

  const _VegetarianSymbol({required this.isVegetarian});

  @override
  Widget build(BuildContext context) {
    final color = isVegetarian ? Colors.green : Colors.red;
    final darkColor = isVegetarian ? Colors.green.shade700 : Colors.red.shade700;
    
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer square outline
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(
                color: darkColor,
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Inner filled circle
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
