import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import '../../services/merchant_service.dart';
import '../../widgets/skeleton_loader.dart';
  import 'add_restaurant_page.dart';

/// Merchant Restaurants Management Page
class MerchantRestaurantsPage extends StatefulWidget {
  const MerchantRestaurantsPage({super.key});

  @override
  State<MerchantRestaurantsPage> createState() => _MerchantRestaurantsPageState();
}

class _MerchantRestaurantsPageState extends State<MerchantRestaurantsPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Defer data loading to avoid blocking main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRestaurants();
    });
  }

  Future<void> _loadRestaurants() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final restaurants = await _merchantService.getMerchantRestaurants();
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load restaurants: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.background,
      appBar: AppBar(
        title: Text(
          'My Restaurants',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: NeoTasteColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRestaurantPage(),
                ),
              ).then((_) => _loadRestaurants());
            },
          ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SkeletonLoader(
                  height: 120,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : _restaurants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant,
                        size: 64,
                        color: NeoTasteColors.textDisabled,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No restaurants yet',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first restaurant to get started',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: NeoTasteColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddRestaurantPage(),
                            ),
                          ).then((_) => _loadRestaurants());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NeoTasteColors.accent,
                          foregroundColor: NeoTasteColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        child: Text(
                          'Add Restaurant',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRestaurants,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = _restaurants[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _RestaurantCard(
                          restaurant: restaurant,
                          onTap: () async {
                            // Use existing restaurant data or fetch full details
                            final restaurantId = restaurant['id'];
                            final id = restaurantId is int
                                ? restaurantId
                                : int.tryParse(restaurantId.toString());
                            
                            if (id != null) {
                              try {
                                final fullRestaurant = await _merchantService.getRestaurantDetails(id);
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddRestaurantPage(restaurant: fullRestaurant),
                                    ),
                                  ).then((refresh) {
                                    if (refresh == true) {
                                      _loadRestaurants();
                                    }
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to load restaurant: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeoTasteColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] as String? ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (restaurant['categories'] != null && (restaurant['categories'] as List).isNotEmpty)
                    Text(
                      (restaurant['categories'] as List).first['name'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: NeoTasteColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: NeoTasteColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant['address'] as String? ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: NeoTasteColors.textSecondary,
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
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: NeoTasteColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
