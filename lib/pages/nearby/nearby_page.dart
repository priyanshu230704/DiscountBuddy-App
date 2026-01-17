import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../../providers/theme_provider.dart';
import '../restaurant_details_page.dart';
import '../search_page.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/city_selector_modal.dart';
import '../../widgets/filter_modal.dart';

/// Nearby Screen - NeoTaste style default map view
class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  bool _showList = false;
  String _cityName = 'London';
  final LatLng _center = const LatLng(51.5074, -0.1278); // London default

  @override
  void initState() {
    super.initState();
    // Defer data loading to avoid blocking main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load city name and restaurants in parallel
      final results = await Future.wait([
        _locationService.getUserCity(),
        _restaurantService.getNearbyRestaurants(
          latitude: _center.latitude,
          longitude: _center.longitude,
        ),
      ]);

      if (mounted) {
        setState(() {
          _cityName = results[0] as String;
          _restaurants = results[1] as List<Restaurant>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cityName = 'London';
          _isLoading = false;
        });
      }
    }
  }

  void _centerMapOnLocation() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_center, 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Stack(
          children: [
          // Full-screen Google Map - Use FutureBuilder to defer initialization
          FutureBuilder<void>(
            future: Future.delayed(const Duration(milliseconds: 100)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 13,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _createMarkers(),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  mapType: MapType.normal,
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                  buildingsEnabled: true,
                  trafficEnabled: false,
                );
              }
              // Show placeholder while map initializes
              return Container(
                color: NeoTasteColors.background,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),

          // Top Navigation Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  // Location Selector
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CitySelectorModal(
                          selectedCity: _cityName,
                          onCitySelected: (city) {
                            setState(() {
                              _cityName = city;
                            });
                            // Reload restaurants for new city
                            _loadData();
                          },
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _cityName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: NeoTasteColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: NeoTasteColors.textPrimary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Promotional Button (Get €10 / Get £10)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green, // Green accent for promotional button
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.card_giftcard,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Get £10',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Search Icon
                  IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: NeoTasteColors.textPrimary,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Middle Control Bar (above bottom navigation)
          Positioned(
            bottom: 80, // Above bottom nav bar
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Filter Button
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: NeoTasteColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            useSafeArea: true,
                            builder: (context) => FilterModal(
                              onApply: (filters) {
                                // Apply filters
                                print('Applied filters: $filters');
                                // Reload restaurants with filters
                                _loadData();
                              },
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.tune,
                              color: NeoTasteColors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filter',
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
                // List Button
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: NeoTasteColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _showList = !_showList;
                          });
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.list,
                              color: NeoTasteColors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'List',
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
                // Compass/Navigation Button (circular)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: NeoTasteColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _centerMapOnLocation,
                      borderRadius: BorderRadius.circular(24),
                      child: const Icon(
                        Icons.navigation,
                        color: NeoTasteColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Restaurant List (bottom sheet when List is tapped)
          if (_showList)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  color: NeoTasteColors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: NeoTasteColors.textDisabled,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'Nearby Restaurants',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: NeoTasteColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _showList = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Restaurant List
                    Expanded(
                      child: _isLoading
                          ? ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: 3,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SkeletonLoader(
                                  height: 100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _restaurants.length,
                              itemBuilder: (context, index) {
                                final restaurant = _restaurants[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _NearbyRestaurantCard(
                                    restaurant: restaurant,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Set<Marker> _createMarkers() {
    final markers = <Marker>{};
    
    // Add user location marker (blue)
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Add restaurant markers (green with 'N' or custom icon)
    for (var restaurant in _restaurants) {
      markers.add(
        Marker(
          markerId: MarkerId(restaurant.id),
          position: LatLng(restaurant.latitude, restaurant.longitude),
          infoWindow: InfoWindow(title: restaurant.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    return markers;
  }
}

/// Nearby Restaurant Card
class _NearbyRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const _NearbyRestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsPage(restaurant: restaurant),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: NeoTasteColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: NeoTasteColors.textDisabled.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: restaurant.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 100,
                  height: 100,
                  color: NeoTasteColors.textDisabled,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 100,
                  height: 100,
                  color: NeoTasteColors.textDisabled,
                  child: const Icon(Icons.restaurant),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Name
                    Text(
                      restaurant.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: NeoTasteColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Cuisine
                    Text(
                      restaurant.cuisine,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: NeoTasteColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        // Distance Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NeoTasteColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: NeoTasteColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${restaurant.distance.toStringAsFixed(1)} km',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: NeoTasteColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Deal Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NeoTasteColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            restaurant.discount.displayText,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: NeoTasteColors.primary,
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
    );
  }
}
