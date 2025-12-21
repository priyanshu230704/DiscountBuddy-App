import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/restaurant.dart';
import '../utils/constants.dart';

/// Restaurant details page
class RestaurantDetailsPage extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailsPage({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: restaurant.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.restaurant, size: 64),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant Info
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingMedium,
                              vertical: AppConstants.paddingSmall,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.white, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  restaurant.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      // Cuisine
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.cuisine,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${restaurant.distance.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      // Description
                      Text(
                        restaurant.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Discount Card
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge,
                  ),
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(AppConstants.accentColorValue),
                        const Color(AppConstants.accentColorValue).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_offer, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            restaurant.discount.displayText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        restaurant.discount.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      if (restaurant.discount.validDays.isNotEmpty) ...[
                        const SizedBox(height: AppConstants.paddingSmall),
                        Text(
                          'Valid: ${restaurant.discount.validDays.join(", ")}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                // Address
                _buildInfoSection(
                  Icons.location_on,
                  'Address',
                  restaurant.address,
                ),
                // Contact
                if (restaurant.phoneNumber.isNotEmpty)
                  _buildInfoSection(
                    Icons.phone,
                    'Phone',
                    restaurant.phoneNumber,
                  ),
                // Opening Hours
                if (restaurant.openingHours.isNotEmpty)
                  _buildInfoSection(
                    Icons.access_time,
                    'Opening Hours',
                    restaurant.openingHours.join('\n'),
                  ),
                // Restrictions
                if (restaurant.restrictions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Important Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        ...restaurant.restrictions.map(
                          (restriction) => Padding(
                            padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 16)),
                                Expanded(
                                  child: Text(
                                    restriction,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (restaurant.requiresBooking)
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_note, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Booking is required for this discount',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppConstants.paddingLarge),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle booking
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppConstants.primaryColorValue),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.paddingMedium,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                            ),
                          ),
                          child: const Text(
                            'Book Table',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // Handle directions
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(AppConstants.primaryColorValue),
                            side: const BorderSide(
                              color: Color(AppConstants.primaryColorValue),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.paddingMedium,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                            ),
                          ),
                          child: const Text(
                            'Get Directions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
        ],
      ),
    );
  }
}

