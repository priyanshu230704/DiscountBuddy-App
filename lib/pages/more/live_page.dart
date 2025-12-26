import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/blurred_ellipse_background.dart';
import '../../widgets/border_gradient.dart';

/// Live page - "What's hot RIGHT NOW?" - Time-sensitive offer feed
class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

// Local constants for live page
class _LiveConstants {
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double radiusLarge = 16.0;
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
      imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400',
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
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
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
      imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
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
      imageUrl: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400',
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
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400',
    ),
  ];

  Timer? _timer;
  String _sortBy = 'distance'; // 'distance', 'time', 'discount'

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

  // Smart throttling: max 5-7 deals, prioritize based on sort option
  List<LiveOffer> get _filteredOffers {
    final sorted = List<LiveOffer>.from(_liveOffers);
    
    switch (_sortBy) {
      case 'time':
        sorted.sort((a, b) => a.expiresAt.compareTo(b.expiresAt)); // Soonest first
        break;
      case 'discount':
        sorted.sort((a, b) => b.discountValue.compareTo(a.discountValue)); // Highest first
        break;
      case 'distance':
      default:
        sorted.sort((a, b) => a.distance.compareTo(b.distance)); // Closer first
        break;
    }
    
    return sorted.take(7).toList();
  }

  Future<void> _refreshOffers() async {
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {});
    }
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
                // Header with live indicator
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _LiveConstants.paddingMedium,
                    vertical: _LiveConstants.paddingMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Live indicator badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Flash Deals",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  '${activeOffers.length} active deals • Act fast!',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _refreshOffers,
                            tooltip: 'Refresh offers',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Quick sort tabs (simplified)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSortChip('time', '⏰ Ending Soon', Icons.schedule),
                            const SizedBox(width: 8),
                            _buildSortChip('distance', '📍 Nearest', Icons.near_me),
                            const SizedBox(width: 8),
                            _buildSortChip('discount', '💰 Biggest Save', Icons.local_offer),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Live Offers List
                Expanded(
                  child: activeOffers.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshOffers,
                          color: const Color(0xFF3E25F6),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(
                              left: _LiveConstants.paddingMedium,
                              right: _LiveConstants.paddingMedium,
                              bottom: _LiveConstants.paddingLarge,
                            ),
                            itemCount: activeOffers.length,
                            itemBuilder: (context, index) {
                              final offer = activeOffers[index];
                              return _buildLiveOfferCard(offer);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3E25F6).withOpacity(0.2)
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3E25F6)
                : Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF3E25F6) : Colors.grey[400],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No live deals right now',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for new offers!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _refreshOffers,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E25F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
    final isUrgent = remaining.inMinutes < 5;

    return Container(
      margin: const EdgeInsets.only(bottom: _LiveConstants.paddingMedium),
      child: BorderGradient(
        borderWidth: isUrgent ? 1.5 : 0.5,
        borderRadius: BorderRadius.circular(_LiveConstants.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1B1F),
            borderRadius: BorderRadius.circular(_LiveConstants.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: urgencyColor.withOpacity(isUrgent ? 0.3 : 0.15),
                blurRadius: isUrgent ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section (compact)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(_LiveConstants.radiusLarge),
                  bottomLeft: Radius.circular(_LiveConstants.radiusLarge),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: offer.imageUrl ?? 'https://via.placeholder.com/400x200?text=Restaurant',
                      width: 120,
                      height: 140,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 120,
                        height: 140,
                        color: const Color(0xFF2B2D30),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3E25F6)),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 140,
                        color: const Color(0xFF2B2D30),
                        child: const Icon(
                          Icons.restaurant,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // Urgency indicator on image
                    if (isUrgent)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                urgencyColor.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Discount badge on image
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              urgencyColor,
                              urgencyColor.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: urgencyColor.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          offer.discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top section: Name and timer
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  offer.restaurantName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (offer.remainingRedemptions > 0 && offer.remainingRedemptions <= 5)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${offer.remainingRedemptions}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (offer.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              offer.description,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Large countdown timer
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: urgencyColor.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: urgencyColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timeRemaining,
                                  style: TextStyle(
                                    color: urgencyColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Bottom section: Location and button
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${offer.distance.toStringAsFixed(1)} km',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          // Compact Get Deal button
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [urgencyColor, urgencyColor.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: urgencyColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Deal activated at ${offer.restaurantName}!'),
                                    backgroundColor: urgencyColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Claim',
                                style: TextStyle(
                                  fontSize: 12,
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
            ],
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
  final String? imageUrl;

  LiveOffer({
    required this.id,
    required this.restaurantName,
    required this.distance,
    required this.discount,
    required this.discountValue,
    required this.expiresAt,
    required this.remainingRedemptions,
    required this.description,
    this.imageUrl,
  });
}
