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
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/generic_bottom_sheet.dart';
import 'deals/redeem_offer_modal.dart';
import 'bookings/booking_selection_modal.dart';

/// Restaurant details page - NeoTaste style
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

  // Show add review dialog
  void _showAddReviewDialog() {
    if (_restaurantDetail == null) return;

    showDialog(
      context: context,
      builder: (context) => _AddReviewDialog(
        restaurantId: int.tryParse(_restaurantDetail!.restaurant.id) ?? 0,
        onSubmit: (rating, comment) async {
          try {
            await _restaurantService.addReview(
              restaurantId: int.tryParse(_restaurantDetail!.restaurant.id) ?? 0,
              rating: rating,
              comment: comment,
            );
            // Reload restaurant to show new review
            if (mounted) {
              Navigator.pop(context); // Close dialog first
              _loadRestaurant();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review added successfully!')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.toString())));
            }
            // Rethrow to let dialog know
            throw e;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: NeoTasteColors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _restaurantDetail == null) {
      return Scaffold(
        backgroundColor: NeoTasteColors.white,
        appBar: AppBar(title: const Text('Restaurant Details')),
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
        cacheExtent:
            500, // Limit off-screen rendering to reduce memory pressure
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
                icon: const Icon(
                  Icons.arrow_back,
                  color: NeoTasteColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: RepaintBoundary(
                child: Stack(
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
                            colors: [Colors.transparent, NeoTasteColors.white],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                            onTap: _toggleFavorite,
                            borderRadius: BorderRadius.circular(24),
                            child: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? Colors.red
                                  : NeoTasteColors.textPrimary,
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
                              final message =
                                  'Check out this deal at ${restaurant.name}!\n\n'
                                  '${restaurant.discount.displayText} - ${restaurant.discount.description}\n\n'
                                  '📍 ${restaurant.address}\n'
                                  'Found on NeoTaste';
                              Share.share(message);
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

          // Offer Card Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (restaurant.activeDeals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Active Offers 📢',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: NeoTasteColors.textPrimary,
                      ),
                    ),
                  ),
                if (restaurant.activeDeals.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _OfferCard(discount: restaurant.discount),
                  ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 17)),
          // Opening Hours Section
          if (restaurant.openingSlots.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _OpeningHoursSection(
                  openingSlots: restaurant.openingSlots,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ratings & reviews',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddReviewDialog,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Write a review'),
                        style: TextButton.styleFrom(
                          foregroundColor: NeoTasteColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Overall Rating
                  InkWell(
                    onTap: _showAddReviewDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                              final halfFilled =
                                  index == rating.floor() && rating % 1 >= 0.5;
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
                    ),
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
                  if (restaurant.postcode != null &&
                      restaurant.postcode!.isNotEmpty) ...[
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
                    if (restaurant.email != null &&
                        restaurant.email!.isNotEmpty)
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
                  RepaintBoundary(
                    child: Container(
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
                            if (_mapController == null) {
                              _mapController = controller;
                            }
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
                          liteModeEnabled:
                              true, // Use lite mode for better performance
                        ),
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
                          final halfFilled =
                              index == rating.floor() && rating % 1 >= 0.5;
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
    if (discount.title != null && discount.title!.isNotEmpty) {
      return discount.title!;
    }
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

  const _OfferChip({required this.icon, required this.text});

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
          Icon(icon, color: NeoTasteColors.white, size: 14),
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
        return GenericBottomSheet(
          title: 'Menu',
          expandChild: true,
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
                          padding: EdgeInsets.only(
                            bottom: 12,
                            top: categoryIndex > 0 ? 24 : 0,
                          ),
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
                        ...category.items.map(
                          (item) => _MenuItemCard(item: item),
                        ),
                      ],
                    );
                  },
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
                padding: const EdgeInsets.only(
                  right: 80,
                ), // Space for symbol + price
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
                  padding: const EdgeInsets.only(
                    right: 80,
                  ), // Space for symbol + price
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '£${item.price}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: NeoTasteColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                _VegetarianSymbol(isVegetarian: item.isVegetarian),
              ],
            ),
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
    final darkColor = isVegetarian
        ? Colors.green.shade700
        : Colors.red.shade700;

    return Container(
      width: 15,
      height: 15,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer square outline
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              border: Border.all(color: darkColor, width: 1.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Inner filled circle
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

/// Opening Hours Section Widget
class _OpeningHoursSection extends StatelessWidget {
  final List<OpeningSlot> openingSlots;

  const _OpeningHoursSection({required this.openingSlots});

  @override
  Widget build(BuildContext context) {
    final currentDay = DateFormat('EEEE').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.access_time_filled,
              color: NeoTasteColors.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Opening Hours',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NeoTasteColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: openingSlots.length,
            itemBuilder: (context, index) {
              final slot = openingSlots[index];
              final isToday =
                  slot.dayName.toLowerCase() == currentDay.toLowerCase();

              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.green.withOpacity(0.05)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday
                        ? Colors.green.withOpacity(0.3)
                        : NeoTasteColors.textDisabled.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slot.dayName.substring(0, 3), // Mon, Tue, etc.
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                        color: isToday
                            ? Colors.green
                            : NeoTasteColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (slot.isClosed)
                      Text(
                        'Closed',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade400,
                        ),
                      )
                    else ...[
                      Text(
                        slot.openingTime,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slot.closingTime,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: NeoTasteColors.textSecondary,
                        ),
                      ),
                    ],
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

class _AddReviewDialog extends StatefulWidget {
  final int restaurantId;
  final Function(int rating, String comment) onSubmit;

  const _AddReviewDialog({required this.restaurantId, required this.onSubmit});

  @override
  State<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<_AddReviewDialog> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a comment')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(_rating, _commentController.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Write a Review',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Comment',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: NeoTasteColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Submit', style: GoogleFonts.inter()),
        ),
      ],
    );
  }
}
