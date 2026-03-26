import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_fonts.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/blurred_ellipse_background.dart';
import '../widgets/common_search_bar.dart';
import '../widgets/border_gradient.dart';
import 'restaurant_details_page.dart';
import '../widgets/app_scaffold.dart';
import '../components/app_app_bar.dart';

/// Browse page with list and map view toggle
class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final RestaurantService _restaurantService = RestaurantService();
  final TextEditingController _searchController = TextEditingController();
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = false;
  bool _isMapView = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final restaurants = await _restaurantService.getNearbyRestaurants(
        latitude: 51.5074,
        longitude: -0.1278,
      );
      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
      _updateMarkers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _filterRestaurants();
  }

  void _filterRestaurants() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        return restaurant.name.toLowerCase().contains(query) ||
            restaurant.cuisine.toLowerCase().contains(query) ||
            restaurant.address.toLowerCase().contains(query);
      }).toList();
    });
    _updateMarkers();
  }

  void _updateMarkers() {
    setState(() {
      _markers = _filteredRestaurants.map((restaurant) {
        return Marker(
          markerId: MarkerId(restaurant.id),
          position: LatLng(restaurant.latitude, restaurant.longitude),
          infoWindow: InfoWindow(
            title: restaurant.name,
            snippet: restaurant.discount.displayText,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantDetailsPage(
                  slug: restaurant.slug ?? restaurant.id,
                ),
              ),
            );
          },
        );
      }).toSet();
    });
  }

  void _toggleView() {
    setState(() {
      _isMapView = !_isMapView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
        body: Stack(
        children: [
          // Blurred ellipse at the top center background
          const BlurredEllipseBackground(),
          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Search Bar Header
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CommonSearchBar(
                          controller: _searchController,
                          hintText: 'Browse • London...',
                          onChanged: (value) {
                            _onSearchChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      BorderGradient(
                        borderWidth: 0.5,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tune,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content (List or Map)
                Expanded(
                  child: _isMapView ? _buildMapView() : _buildListView(),
                ),
              ],
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: 100,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.card,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleView,
                  borderRadius: BorderRadius.circular(28),
                  child: Icon(
                    _isMapView ? Icons.list : Icons.map,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading restaurants...');
    }

    if (_filteredRestaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              'No restaurants found',
              style: AppFonts.titleStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _filteredRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _filteredRestaurants[index];
        return RestaurantCard(
          restaurant: restaurant,
          onTap: () {
            final slug = restaurant.slug ?? restaurant.id;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantDetailsPage(slug: slug),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapView() {
    // Note: Google Maps requires an API key in AndroidManifest.xml
    // If you see an error, add your API key to:
    // android/app/src/main/AndroidManifest.xml
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(51.5074, -0.1278), // London
            zoom: 13,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        // Restaurant Card at Bottom (Tastecard style)
        if (_filteredRestaurants.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              margin: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.xLarge,
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppShadows.card,
                ),
                child: InkWell(
                  onTap: () {
                    final restaurant = _filteredRestaurants[0];
                    final slug = restaurant.slug ?? restaurant.id;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailsPage(slug: slug),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(
                            24,
                          ),
                          bottomLeft: Radius.circular(
                            24,
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: _filteredRestaurants[0].imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.restaurant),
                          ),
                        ),
                      ),
                      // Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _filteredRestaurants[0].discount.displayText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _filteredRestaurants[0].name,
                                  style: AppFonts.titleStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _filteredRestaurants[0].address,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _filteredRestaurants[0]
                                        .discount
                                        .validDays
                                        .isNotEmpty
                                    ? _filteredRestaurants[0].discount.validDays
                                          .join(' - ')
                                    : 'Mon - Sun',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Thumbs Up and Bookmark
                      Padding(
                        padding: const EdgeInsets.all(
                          AppSpacing.sm,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.bookmark_border),
                              onPressed: () {},
                            ),
                            Row(
                              children: [
                                const Icon(Icons.thumb_up, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${_filteredRestaurants[0].reviewCount}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
