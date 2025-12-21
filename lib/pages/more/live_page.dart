import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/constants.dart';
import '../../widgets/blurred_ellipse_background.dart';
import '../../widgets/border_gradient.dart';

/// Live page - "What's hot RIGHT NOW?" - Time-sensitive offer feed
class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final List<LiveOffer> _liveOffers = [
    LiveOffer(
      id: '1',
      restaurantName: 'Caffè Nero',
      distance: 0.8,
      discount: '25% OFF',
      discountValue: 25,
      expiresAt: DateTime.now().add(const Duration(minutes: 37)),
      remainingRedemptions: 5,
      description: 'On all hot beverages',
    ),
    LiveOffer(
      id: '2',
      restaurantName: 'Prezzo',
      distance: 1.2,
      discount: '50% OFF',
      discountValue: 50,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      remainingRedemptions: 2,
      description: 'Main courses only',
    ),
    LiveOffer(
      id: '3',
      restaurantName: 'Bella Italia',
      distance: 2.1,
      discount: '2-FOR-1',
      discountValue: 50,
      expiresAt: DateTime.now().add(const Duration(minutes: 52)),
      remainingRedemptions: 8,
      description: 'Selected pizzas',
    ),
    LiveOffer(
      id: '4',
      restaurantName: 'ASK Italian',
      distance: 1.5,
      discount: '30% OFF',
      discountValue: 30,
      expiresAt: DateTime.now().add(const Duration(minutes: 8)),
      remainingRedemptions: 3,
      description: 'Dinner special',
    ),
    LiveOffer(
      id: '5',
      restaurantName: 'Zizzi',
      distance: 0.9,
      discount: '40% OFF',
      discountValue: 40,
      expiresAt: DateTime.now().add(const Duration(minutes: 23)),
      remainingRedemptions: 12,
      description: 'All pasta dishes',
    ),
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update countdown every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          // Auto-remove expired offers
          _liveOffers.removeWhere((offer) => offer.expiresAt.isBefore(DateTime.now()));
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Smart throttling: max 5-7 deals, prioritize closer places
  List<LiveOffer> get _filteredOffers {
    final sorted = List<LiveOffer>.from(_liveOffers)
      ..sort((a, b) => a.distance.compareTo(b.distance)); // Closer first
    return sorted.take(7).toList();
  }

  String _formatTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return 'Expired';
    
    final difference = expiresAt.difference(now);
    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    
    if (minutes > 0) {
      return '$minutes min ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Color _getUrgencyColor(Duration remaining) {
    if (remaining.inMinutes < 5) {
      return Colors.red;
    } else if (remaining.inMinutes < 15) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOffers = _filteredOffers.where((offer) => 
      offer.expiresAt.isAfter(DateTime.now())
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          const BlurredEllipseBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    left: AppConstants.paddingMedium,
                    right: AppConstants.paddingMedium,
                    bottom: AppConstants.paddingMedium,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          "What's hot RIGHT NOW?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live Offers List
                Expanded(
                  child: activeOffers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No live deals right now',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check back soon for new offers!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: AppConstants.paddingMedium,
                            right: AppConstants.paddingMedium,
                            bottom: AppConstants.paddingLarge,
                          ),
                          itemCount: activeOffers.length,
                          itemBuilder: (context, index) {
                            final offer = activeOffers[index];
                            return _buildLiveOfferCard(offer);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveOfferCard(LiveOffer offer) {
    final remaining = offer.expiresAt.difference(DateTime.now());
    final timeRemaining = _formatTimeRemaining(offer.expiresAt);
    final urgencyColor = _getUrgencyColor(remaining);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: BorderGradient(
        borderWidth: 1,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1B1F),
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: urgencyColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with discount, timer, and count left
                Row(
                  children: [
                    // Discount badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              urgencyColor,
                              urgencyColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          offer.discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Timer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: urgencyColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: urgencyColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeRemaining,
                            style: TextStyle(
                              color: urgencyColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (offer.remainingRedemptions > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning,
                              size: 14,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${offer.remainingRedemptions} left',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Restaurant info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.restaurantName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (offer.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              offer.description,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${offer.distance.toStringAsFixed(1)} km away',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    // Get Deal Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [urgencyColor, urgencyColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: urgencyColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle deal redemption
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deal activated at ${offer.restaurantName}!'),
                              backgroundColor: urgencyColor,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Get Deal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

class LiveOffer {
  final String id;
  final String restaurantName;
  final double distance; // in km
  final String discount;
  final int discountValue;
  final DateTime expiresAt;
  final int remainingRedemptions;
  final String description;

  LiveOffer({
    required this.id,
    required this.restaurantName,
    required this.distance,
    required this.discount,
    required this.discountValue,
    required this.expiresAt,
    required this.remainingRedemptions,
    required this.description,
  });
}
