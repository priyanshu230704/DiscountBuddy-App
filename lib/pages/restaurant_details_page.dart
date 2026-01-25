import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/restaurant.dart';
import '../providers/theme_provider.dart';
import 'deals/redeem_offer_modal.dart';

/// Restaurant details page - NeoTaste style
class RestaurantDetailsPage extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailsPage({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  bool _isFavorite = false;

  // Convert km to miles
  double _kmToMiles(double km) {
    return km * 0.621371;
  }

  // Get opening hours (mock - using first opening hour or default)
  String _getOpeningHours() {
    if (widget.restaurant.openingHours.isNotEmpty) {
      return 'Open until ${widget.restaurant.openingHours[0]}';
    }
    return 'Open until 22:00';
  }

  // Get price range (mock - based on cuisine)
  String _getPriceRange() {
    return '££££';
  }

  @override
  Widget build(BuildContext context) {
    final distanceMiles = _kmToMiles(widget.restaurant.distance);

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
                    imageUrl: widget.restaurant.imageUrl,
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
                    widget.restaurant.name,
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
                            widget.restaurant.cuisine,
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
                              '${widget.restaurant.address.split(',').first} (${distanceMiles.toStringAsFixed(2)} mi)',
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
                            _getPriceRange(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: NeoTasteColors.textPrimary,
                            ),
                          ),
                          Text(
                            ' ${_getOpeningHours()}',
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
                                // Navigate to menu
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
                discount: widget.restaurant.discount,
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
                        widget.restaurant.rating.toStringAsFixed(1),
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
                          final rating = widget.restaurant.rating;
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
                    '${widget.restaurant.reviewCount} ratings | ${widget.restaurant.reviewCount} reviews',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: NeoTasteColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Individual Reviews
                  ..._getMockReviews().map((review) => _ReviewItem(review: review)),
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
                    widget.restaurant.address,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
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
                            widget.restaurant.latitude,
                            widget.restaurant.longitude,
                          ),
                          zoom: 15,
                        ),
                        onMapCreated: (controller) {
                          // Map controller initialized
                        },
                        markers: {
                          Marker(
                            markerId: MarkerId(widget.restaurant.id),
                            position: LatLng(
                              widget.restaurant.latitude,
                              widget.restaurant.longitude,
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
                  restaurant: widget.restaurant,
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

  // Mock reviews data
  List<_Review> _getMockReviews() {
    return [
      _Review(
        name: 'Gary',
        rating: 4.0,
        timeAgo: '4 months ago',
        comment: null,
        verified: true,
      ),
      _Review(
        name: 'Marlin',
        rating: 4.0,
        timeAgo: '5 months ago',
        comment: null,
        verified: true,
      ),
      _Review(
        name: 'Sam',
        rating: 3.0,
        timeAgo: '8 months ago',
        comment: "Don't know what they're doing behind the bar. Took 30 minutes to get a drink and there was barely a queue",
        verified: true,
      ),
    ];
  }
}

/// Review Model
class _Review {
  final String name;
  final double rating;
  final String timeAgo;
  final String? comment;
  final bool verified;

  _Review({
    required this.name,
    required this.rating,
    required this.timeAgo,
    this.comment,
    this.verified = false,
  });
}

/// Review Item Widget
class _ReviewItem extends StatelessWidget {
  final _Review review;

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
                  _getInitials(review.name),
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
                    review.name,
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
                          final filled = index < review.rating.floor();
                          final halfFilled = index == review.rating.floor() && review.rating % 1 >= 0.5;
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
                      if (review.verified) ...[
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
