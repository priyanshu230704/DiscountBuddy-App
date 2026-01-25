import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../../providers/theme_provider.dart';
import '../restaurant_details_page.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  GoogleMapController? _mapController;
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = true;
  bool _showList = false;
  bool _isSearching = false;
  String _cityName = 'London';
  final LatLng _center = const LatLng(51.5074, -0.1278); // London default

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Defer data loading to avoid blocking main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // Update UI for suffix icon
    _filterRestaurants();
  }

  void _filterRestaurants() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredRestaurants = _restaurants;
      } else {
        _filteredRestaurants = _restaurants.where((restaurant) {
          return restaurant.name.toLowerCase().contains(query) ||
              restaurant.cuisine.toLowerCase().contains(query) ||
              restaurant.description.toLowerCase().contains(query);
        }).toList();
      }
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
          _filteredRestaurants = results[1] as List<Restaurant>;
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
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show full-screen list view when _showList is true
    if (_showList) {
      return PopScope(
        canPop: !_isSearching,
        onPopInvoked: (didPop) {
          if (!didPop && _isSearching) {
            _searchController.clear();
            _searchFocusNode.unfocus();
            setState(() {
              _isSearching = false;
            });
          }
        },
        child: Scaffold(
          backgroundColor: NeoTasteColors.background,
          body: RefreshIndicator(
          onRefresh: _loadData,
          child: Column(
            children: [
              // Top Navigation Bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _isSearching
                      ? // Search Mode - Center search bar
                      Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: NeoTasteColors.textPrimary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                                setState(() {
                                  _isSearching = false;
                                });
                              },
                            ),
                            Expanded(
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _searchController,
                                builder: (context, value, child) {
                                  return TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'Search restaurants...',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: NeoTasteColors.textSecondary,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: NeoTasteColors.textSecondary,
                                        size: 20,
                                      ),
                                      suffixIcon: value.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: NeoTasteColors.textSecondary,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: NeoTasteColors.textPrimary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : // Normal Mode - Location, Get £10, Search icon
                      Row(
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
                            // Promotional Button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
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
                                setState(() {
                                  _isSearching = true;
                                });
                                // Request focus after build
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _searchFocusNode.requestFocus();
                                });
                              },
                            ),
                          ],
                        ),
                ),
              ),
              // Recommended Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: NeoTasteColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recommended',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: NeoTasteColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              // Restaurant List
              Expanded(
                child: _isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 5,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SkeletonLoader(
                            height: 140,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredRestaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = _filteredRestaurants[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ListRestaurantCard(restaurant: restaurant),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Bottom buttons - Map and Filter
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Filter Button
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            print('Applied filters: $filters');
                            _loadData();
                          },
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
              const SizedBox(width: 12),
              // Map Button
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        _showList = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map,
                          color: NeoTasteColors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Map',
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
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
      );
    }

    // Default map view
    return PopScope(
      canPop: !_isSearching,
      onPopInvoked: (didPop) {
        if (!didPop && _isSearching) {
          _searchController.clear();
          _searchFocusNode.unfocus();
          setState(() {
            _isSearching = false;
          });
        }
      },
      child: Scaffold(
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
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),

            // Top Navigation Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _isSearching
                    ? // Search Mode - Center search bar
                    Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: NeoTasteColors.textPrimary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              setState(() {
                                _isSearching = false;
                              });
                            },
                          ),
                          Expanded(
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _searchController,
                              builder: (context, value, child) {
                                return TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'Search restaurants...',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: NeoTasteColors.textSecondary,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: NeoTasteColors.textSecondary,
                                      size: 20,
                                    ),
                                    suffixIcon: value.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: NeoTasteColors.textSecondary,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: NeoTasteColors.textPrimary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : // Normal Mode - Location, Get £10, Search icon
                    Row(
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
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
                              setState(() {
                                _isSearching = true;
                              });
                              // Request focus after build
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _searchFocusNode.requestFocus();
                              });
                            },
                          ),
                        ],
                      ),
              ),
            ),

            // Middle Control Bar (above bottom navigation)
            Positioned(
              bottom: 60, // Above bottom nav bar
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
                              _showList = true;
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
          ],
        ),
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
    for (var restaurant in _filteredRestaurants) {
      markers.add(
        Marker(
          markerId: MarkerId(restaurant.id),
          position: LatLng(restaurant.latitude, restaurant.longitude),
          infoWindow: InfoWindow(title: restaurant.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    return markers;
  }
}

/// List Restaurant Card (matches image design)
class _ListRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const _ListRestaurantCard({required this.restaurant});

  // Convert km to miles
  double _kmToMiles(double km) {
    return km * 0.621371;
  }

  // Generate offer tags based on discount
  List<String> _getOfferTags() {
    final tags = <String>[];
    final desc = restaurant.discount.description.toLowerCase();

    // Main discount tag
    switch (restaurant.discount.type) {
      case '2for1':
        if (desc.contains('wings')) {
          tags.add('2for1 Signature Wings');
        } else if (desc.contains('rodizio')) {
          tags.add('2for1 Rodizio');
        } else if (desc.contains('course')) {
          tags.add('2for1 Main Course');
        } else if (desc.contains('main')) {
          tags.add('2for1 Main Item');
        } else {
          tags.add('2for1 Main Item');
        }
        break;
      case 'percentage':
        tags.add('${restaurant.discount.percentage?.toInt()}% Discount');
        break;
      case 'fixed':
        tags.add(
          '£${restaurant.discount.fixedAmount?.toStringAsFixed(0)} Discount',
        );
        break;
    }

    // Add additional free items based on description
    if (desc.contains('dessert')) {
      tags.add('FREE Dessert');
    }
    if (desc.contains('drink') || desc.contains('soft drink')) {
      tags.add('FREE Soft Drink');
    }
    if (desc.contains('caipirinha')) {
      tags.add('FREE Caipirinha');
    }
    if (desc.contains('side')) {
      tags.add('FREE Side Dish');
    }

    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final offerTags = _getOfferTags();
    final distanceMiles = _kmToMiles(restaurant.distance);

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: NeoTasteColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Rating, Distance, and Cuisine in one row
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: NeoTasteColors.textPrimary,
                          ),
                        ),
                        Text(
                          ' (${restaurant.reviewCount})',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: NeoTasteColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 12,
                          color: NeoTasteColors.textDisabled.withOpacity(0.3),
                        ),
                        const SizedBox(width: 8),
                        // Distance
                        Text(
                          '${distanceMiles.toStringAsFixed(2)} mi',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: NeoTasteColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Cuisine
                        Flexible(
                          child: Text(
                            restaurant.cuisine,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: NeoTasteColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Offer Tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: offerTags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
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
