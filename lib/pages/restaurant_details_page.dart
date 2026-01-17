import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/restaurant.dart';
import '../providers/theme_provider.dart';
import 'deals/redeem_offer_modal.dart';

/// Restaurant details page - NeoTaste style
class RestaurantDetailsPage extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailsPage({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.background,
      body: CustomScrollView(
        slivers: [
          // Header with full-width image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: NeoTasteColors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                  // Gradient fade
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

          // Restaurant Info
          SliverToBoxAdapter(
            child: Container(
              color: NeoTasteColors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    restaurant.name,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rating + Reviews
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${restaurant.reviewCount} reviews)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: NeoTasteColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Address + Distance
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: NeoTasteColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.address,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: NeoTasteColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: NeoTasteColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${restaurant.distance.toStringAsFixed(1)} km',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: NeoTasteColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Deals Section
          SliverToBoxAdapter(
            child: Container(
              color: NeoTasteColors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Deals',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DealCard(
                    title: restaurant.discount.displayText,
                    description: restaurant.discount.description,
                    validDays: restaurant.discount.validDays,
                    validTime: restaurant.discount.validTime,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
              // Show redeem modal
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
              backgroundColor: NeoTasteColors.accent,
              foregroundColor: NeoTasteColors.primary,
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
}

/// Deal Card in Restaurant Details
class _DealCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> validDays;
  final String? validTime;

  const _DealCard({
    required this.title,
    required this.description,
    required this.validDays,
    this.validTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NeoTasteColors.accent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deal Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: NeoTasteColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: NeoTasteColors.textSecondary,
            ),
          ),
          if (validDays.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: NeoTasteColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Valid: ${validDays.join(", ")}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: NeoTasteColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          if (validTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: NeoTasteColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  validTime!,
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
    );
  }
}
