import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../services/restaurant_service.dart';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/loading_widget.dart';
import 'restaurant_details_page.dart';
import '../widgets/app_scaffold.dart';
import '../components/app_app_bar.dart';

class SavedRestaurantsPage extends StatefulWidget {
  const SavedRestaurantsPage({super.key});

  @override
  State<SavedRestaurantsPage> createState() => _SavedRestaurantsPageState();
}

class _SavedRestaurantsPageState extends State<SavedRestaurantsPage> {
  final RestaurantService _restaurantService = RestaurantService();
  List<Restaurant> _savedRestaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    setState(() => _isLoading = true);
    try {
      final restaurants = await _restaurantService.getSavedRestaurants();
      
      // Calculate distances manually if API doesn't provide accurate distance
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        ).catchError((_) => throw Exception("Timeout"));

        for (int i = 0; i < restaurants.length; i++) {
          final r = restaurants[i];
          final distanceInMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            r.latitude,
            r.longitude,
          );
          // Convert meters to miles
          restaurants[i] = r.copyWith(distanceMiles: distanceInMeters / 1609.344);
        }
      } catch (e) {
        debugPrint('Location fetching failed for saved restaurants calculation: $e');
      }

      if (mounted) {
        setState(() {
          _savedRestaurants = restaurants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load saved restaurants: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Saved Restaurants',
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading favorites...')
          : _savedRestaurants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      Text(
                        'No saved restaurants yet',
                        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSaved,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _savedRestaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = _savedRestaurants[index];
                      return RestaurantCard(
                        restaurant: restaurant,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailsPage(
                                slug: restaurant.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            ),
    );
  }
}
