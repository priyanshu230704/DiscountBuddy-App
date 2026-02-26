import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;

import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../restaurant_details_page.dart';
import '../notifications_page.dart';
import '../../widgets/city_selector_modal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum HomeFilter { offers, rating, nearest, openNow }

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final AuthProvider _authProvider = AuthProvider();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Restaurant> _restaurants = [];
  List<Restaurant> _nearbyRestaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  List<Map<String, dynamic>> _cuisineSections = [];

  bool _isLoading = true;
  bool _isSearching = false;

  String _cityName = 'Detecting...';
  int _notificationCount = 0;
  StreamSubscription<RemoteMessage>? _notificationSubscription;

  double _userLatitude = 0;
  double _userLongitude = 0;

  HomeFilter? _activeFilter;
  static const Color buddyPink = Color(0xFFFF2D83);
  static const Color buddyPurple = Color(0xFF7C3AED);
  static const Color buddyOrange = Color(0xFFFF7A00);
  static const Color buddyYellow = Color(0xFFFFB100);

  static const Color bg = Color(0xFFF7F8FA);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static const List<Color> buddyGradient = [
    buddyPink,
    buddyPurple,
    buddyOrange,
    buddyYellow,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocationAndLoadData();
    _loadNotificationCount();
    _searchController.addListener(_onSearchChanged);

    debugPrint("🔔 Setting up FCM listener in HomePage");
    _notificationSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      debugPrint("🔔 FCM Message Received: ${message.messageId}");
      if (message.notification != null) {
        debugPrint("   Title: ${message.notification?.title}");
        debugPrint("   Body: ${message.notification?.body}");
      }

      if (mounted) {
        debugPrint(
          "   Updating notification count: $_notificationCount -> ${_notificationCount + 1}",
        );
        setState(() {
          _notificationCount++;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // If we are currently on fallback (coords are 0 or London), try to get real location
      if (_userLatitude == 0 ||
          (_userLatitude == 51.5074 && _userLongitude == -0.1278)) {
        _onReturnedFromSettings();
      }
    }
  }

  /// Called when user returns to the app after visiting settings
  Future<void> _onReturnedFromSettings() async {
    try {
      final location = await _locationService.getUserLocation();
      if (mounted) {
        setState(() {
          _userLatitude = location.position.latitude;
          _userLongitude = location.position.longitude;
          _cityName = location.cityName;
        });
        // Reload restaurants with the new coordinates
        await _loadRestaurants();
      }
    } catch (_) {
      debugPrint('📍 Still no location after settings, using defaults');
      if (mounted) {
        setState(() {
          _userLatitude = 51.5074;
          _userLongitude = -0.1278;
          _cityName = 'London';
        });
        await _loadRestaurants();
      }
    }
  }

  void _onSearchChanged() => _filterRestaurants();

  void _filterRestaurants() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredRestaurants = _applyFilter(_restaurants);
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredRestaurants = _applyFilter(
          _restaurants.where((restaurant) {
            return restaurant.name.toLowerCase().contains(query) ||
                restaurant.cuisine.toLowerCase().contains(query) ||
                restaurant.description.toLowerCase().contains(query);
          }).toList(),
        );
      }
    });
  }

  /// Fetch user location first (system dialog handles permission prompt),
  /// then load restaurants using the real lat/lon.
  Future<void> _initLocationAndLoadData() async {
    try {
      final location = await _locationService.getUserLocation();
      if (mounted) {
        setState(() {
          _userLatitude = location.position.latitude;
          _userLongitude = location.position.longitude;
          _cityName = location.cityName;
        });
      }
    } on LocationServiceDisabledException {
      debugPrint('📍 Location services disabled');
      if (mounted) {
        setState(() => _cityName = 'Location Off');
        _promptToEnableLocation(
          'Location services are off.',
          isServiceOff: true,
        );
      }
    } on LocationPermissionDeniedException {
      debugPrint('📍 Location permission denied');
      if (mounted) {
        setState(() => _cityName = 'No Permission');
        _promptToEnableLocation(
          'Location permission denied.',
          isServiceOff: false,
        );
      }
    } catch (e) {
      debugPrint('📍 Location unavailable, using defaults: $e');
      if (mounted) {
        setState(() {
          _userLatitude = 51.5074;
          _userLongitude = -0.1278;
          _cityName = 'London';
        });
      }
    } finally {
      await _loadRestaurants();
    }
  }

  /// Show a snackbar or subtle indicator to enable location if it's currently off
  void _promptToEnableLocation(String message, {required bool isServiceOff}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () async {
            if (isServiceOff) {
              await Geolocator.openLocationSettings();
            } else {
              await Geolocator.openAppSettings();
            }
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _loadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) setState(() => _notificationCount = count);
    } catch (_) {
      // Silently fail - notification count is not critical
      if (mounted) setState(() => _notificationCount = 0);
    }
  }

  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);

    try {
      if (_authProvider.isCustomer) {
        final homeData = await _restaurantService.getHomeData(
          latitude: _userLatitude,
          longitude: _userLongitude,
        );

        final Map<int, String> cuisineMap = {};
        final cuisinesJson = homeData['cuisines'] as List<dynamic>? ?? [];

        for (final cuisineGroup in cuisinesJson) {
          if (cuisineGroup is Map<String, dynamic>) {
            final cuisine = cuisineGroup['cuisine'] as Map<String, dynamic>?;
            final cuisineName = cuisine?['name'] as String? ?? 'Restaurant';

            final restaurants =
                cuisineGroup['restaurants'] as List<dynamic>? ?? [];
            for (final restaurant in restaurants) {
              if (restaurant is Map<String, dynamic>) {
                final restaurantId = restaurant['id'] as int?;
                if (restaurantId != null)
                  cuisineMap[restaurantId] = cuisineName;
              }
            }
          }
        }

        final allRestaurantsJson =
            homeData['all_restaurants'] as List<dynamic>? ?? [];
        final nearbyRestaurantsJson =
            homeData['nearby'] as List<dynamic>? ?? [];

        final allRestaurants = allRestaurantsJson
            .map(
              (json) => _restaurantService.convertApiRestaurantToModel(
                json as Map<String, dynamic>,
                cuisineMap: cuisineMap,
              ),
            )
            .toList();

        final nearbyRestaurants = nearbyRestaurantsJson
            .map(
              (json) => _restaurantService.convertApiRestaurantToModel(
                json as Map<String, dynamic>,
                cuisineMap: cuisineMap,
              ),
            )
            .toList();

        // Sort by leaderboard score (highest first)
        allRestaurants.sort(
          (a, b) => b.leaderboardScore.compareTo(a.leaderboardScore),
        );
        nearbyRestaurants.sort(
          (a, b) => b.leaderboardScore.compareTo(a.leaderboardScore),
        );

        final List<Map<String, dynamic>> cuisineSections = [];
        for (final group in cuisinesJson) {
          if (group is Map<String, dynamic>) {
            final cuisine = group['cuisine'] as Map<String, dynamic>?;
            if (cuisine != null) {
              final restaurantsJson =
                  group['restaurants'] as List<dynamic>? ?? [];
              final restaurants = restaurantsJson
                  .map(
                    (r) => _restaurantService.convertApiRestaurantToModel(
                      r as Map<String, dynamic>,
                      cuisineMap: cuisineMap,
                    ),
                  )
                  .toList();

              // Sort by leaderboard score (highest first)
              restaurants.sort(
                (a, b) => b.leaderboardScore.compareTo(a.leaderboardScore),
              );

              cuisineSections.add({
                'id': cuisine['id'],
                'name': cuisine['name'],
                'icon': cuisine['icon'],
                'restaurants': restaurants,
              });
            }
          }
        }

        if (!mounted) return;
        setState(() {
          _restaurants = allRestaurants;
          _nearbyRestaurants = nearbyRestaurants;
          _filteredRestaurants = _applyFilter(allRestaurants);
          _cuisineSections = cuisineSections;
          _isLoading = false;
        });
      } else {
        // Use real user coordinates from location permission
        final restaurants = await _restaurantService.getNearbyRestaurants(
          latitude: _userLatitude,
          longitude: _userLongitude,
        );

        if (!mounted) return;
        setState(() {
          _restaurants = restaurants;
          _filteredRestaurants = _applyFilter(restaurants);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _kmToMiles(double km) => km * 0.621371;

  List<String> _getOfferTags(Restaurant restaurant) {
    final tags = <String>[];
    final desc = restaurant.discount.description.toLowerCase();

    switch (restaurant.discount.type) {
      case '2for1':
        tags.add("2for1 Deal");
        break;
      case 'percentage':
        tags.add("${restaurant.discount.percentage?.toInt() ?? 0}% OFF");
        break;
      case 'fixed':
        tags.add(
          "£${restaurant.discount.fixedAmount?.toStringAsFixed(0) ?? "0"} OFF",
        );
        break;
    }

    if (desc.contains('dessert')) tags.add("FREE Dessert");
    if (desc.contains('drink') || desc.contains('soft drink'))
      tags.add("FREE Drink");
    if (desc.contains('side')) tags.add("FREE Side");

    return tags;
  }

  List<Restaurant> _applyFilter(List<Restaurant> list) {
    final copy = [...list];

    switch (_activeFilter) {
      case HomeFilter.offers:
        copy.sort((a, b) => b.leaderboardScore.compareTo(a.leaderboardScore));
        return copy;
      case HomeFilter.rating:
        copy.sort((a, b) => b.rating.compareTo(a.rating));
        return copy;
      case HomeFilter.nearest:
        copy.sort((a, b) => a.distance.compareTo(b.distance));
        return copy;
      case HomeFilter.openNow:
        return copy;
      default:
        return copy;
    }
  }

  void _toggleFilter(HomeFilter filter) {
    setState(() {
      _activeFilter = (_activeFilter == filter) ? null : filter;
      _filteredRestaurants = _applyFilter(_restaurants);
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _isSearching
        ? _filteredRestaurants
        : _applyFilter(_restaurants);

    return PopScope(
      canPop: !_isSearching,
      onPopInvoked: (didPop) {
        if (!didPop && _isSearching) {
          _searchController.clear();
          _searchFocusNode.unfocus();
          setState(() => _isSearching = false);
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        body: RefreshIndicator(
          onRefresh: _loadRestaurants,
          color: buddyOrange,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              if (!_isSearching) _buildBanners(),
              if (!_isSearching) _buildBestOffers(),
              if (!_isSearching) _buildCuisineRow(),
              _buildRestaurantFeed(list),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = 176 + topPadding;

    return SliverAppBar(
      pinned: false,
      floating: false,
      snap: false,
      elevation: 0,
      backgroundColor: bg,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      expandedHeight: headerHeight,

      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                buddyPink.withOpacity(0.09),
                buddyOrange.withOpacity(0.09),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(colors: buddyGradient),
                          boxShadow: [
                            BoxShadow(
                              color: buddyPink.withOpacity(0.20),
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            "assets/png/db_logo.png",
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.local_offer,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Discount Buddy",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.black.withOpacity(0.06),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return const LinearGradient(
                                  colors: buddyGradient,
                                ).createShader(bounds);
                              },
                              child: const Icon(
                                Icons.flash_on,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Live Deals",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Notification Icon with Badge
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsPage(),
                            ),
                          );
                          // Reload notification count when returning
                          _loadNotificationCount();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.notifications_outlined,
                                  size: 22,
                                  color: textPrimary,
                                ),
                              ),
                              if (_notificationCount > 0)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: buddyGradient,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: buddyOrange.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _notificationCount > 99
                                            ? '99+'
                                            : _notificationCount.toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _isSearching
                      ? _SearchBar(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onClose: () {
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                            setState(() => _isSearching = false);
                          },
                        )
                      : Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_cityName == 'Location Off' ||
                                    _cityName == 'No Permission') {
                                  _promptToEnableLocation(
                                    _cityName == 'Location Off'
                                        ? 'Location services are disabled'
                                        : 'Location permission is denied',
                                    isServiceOff: _cityName == 'Location Off',
                                  );
                                  return;
                                }
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => CitySelectorModal(
                                    selectedCity: _cityName,
                                    onCitySelected: (city) {
                                      setState(() {
                                        _cityName = city.name;
                                      });
                                      _loadRestaurants();
                                    },
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return const LinearGradient(
                                        colors: buddyGradient,
                                      ).createShader(bounds);
                                    },
                                    child: Icon(
                                      _cityName == 'Location Off' ||
                                              _cityName == 'No Permission'
                                          ? Icons.location_off
                                          : Icons.location_on,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _cityName,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          _cityName == 'Location Off' ||
                                              _cityName == 'No Permission'
                                          ? Colors.redAccent
                                          : textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (_cityName != 'Location Off' &&
                                      _cityName != 'No Permission')
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: textSecondary,
                                    ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                setState(() => _isSearching = true);
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => _searchFocusNode.requestFocus(),
                                );
                              },
                              icon: const Icon(
                                Icons.search,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),

                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChipX(
                          text: "✨ Best Near You",
                          active: _activeFilter == HomeFilter.offers,
                          onTap: () => _toggleFilter(HomeFilter.offers),
                        ),
                        _FilterChipX(
                          text: "⭐ Top Rated",
                          active: _activeFilter == HomeFilter.rating,
                          onTap: () => _toggleFilter(HomeFilter.rating),
                        ),
                        _FilterChipX(
                          text: "📍 Nearest",
                          active: _activeFilter == HomeFilter.nearest,
                          onTap: () => _toggleFilter(HomeFilter.nearest),
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
    );
  }

  Widget _buildBanners() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: SizedBox(
          height: 150,
          child: PageView(
            controller: PageController(viewportFraction: 0.92),
            children: const [
              _GradientBanner(
                title: "Best Recommendations",
                subtitle: "Top-rated restaurants near you",
                emoji: "✨",
              ),
              _GradientBanner(
                title: "Buddy Picks",
                subtitle: "Hot deals from top restaurants",
                emoji: "🔥",
              ),
              _GradientBanner(
                title: "Save More Today",
                subtitle: "Extra freebies + combo discounts",
                emoji: "😋",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBestOffers() {
    if (_isLoading) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final nearby = _nearbyRestaurants;
    if (nearby.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
            child: Text(
              "Best Restaurants Near You ✨",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 330,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: nearby.length,
              itemBuilder: (context, index) {
                return _BestOfferCard(
                  restaurant: nearby[index],
                  kmToMiles: _kmToMiles,
                  offerTags: _getOfferTags,
                  userLat: _userLatitude,
                  userLon: _userLongitude,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuisineRow() {
    if (_cuisineSections.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Text(
                "Explore Cuisines",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
            ),
            SizedBox(
              height: 92,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _cuisineSections.length,
                itemBuilder: (context, index) {
                  final c = _cuisineSections[index];
                  return _CuisineChipX(
                    icon: c['icon'] ?? "🍴",
                    name: c['name'] ?? "",
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantFeed(List<Restaurant> list) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator(color: buddyOrange)),
        ),
      );
    }

    if (list.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
            child: Text(
              "No restaurants found 😅",
              style: TextStyle(color: textSecondary),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _FeedTile(
              restaurant: list[index],
              kmToMiles: _kmToMiles,
              offerTags: _getOfferTags,
              userLat: _userLatitude,
              userLon: _userLongitude,
            ),
          );
        }, childCount: list.length),
      ),
    );
  }
}

/* ------------------- Premium Widgets ------------------- */

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClose;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 20, color: Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: "Search restaurants, cuisines...",
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _FilterChipX extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _FilterChipX({
    required this.text,
    required this.active,
    required this.onTap,
  });

  static const List<Color> buddyGradient = [
    Color(0xFFFF2D83),
    Color(0xFF7C3AED),
    Color(0xFFFF7A00),
    Color(0xFFFFB100),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          height: 36,
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: active ? null : Colors.white,
            gradient: active
                ? const LinearGradient(colors: buddyGradient)
                : null,
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: buddyGradient.first.withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;

  const _GradientBanner({
    required this.title,
    required this.subtitle,
    required this.emoji,
  });

  static const List<Color> buddyGradient = [
    Color(0xFFFF2D83),
    Color(0xFF7C3AED),
    Color(0xFFFF7A00),
    Color(0xFFFFB100),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: buddyGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: buddyGradient.first.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Explore",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 48)),
        ],
      ),
    );
  }
}

class _CuisineChipX extends StatelessWidget {
  final String icon;
  final String name;

  const _CuisineChipX({required this.icon, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 72,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BestOfferCard extends StatelessWidget {
  final Restaurant restaurant;
  final double Function(double) kmToMiles;
  final List<String> Function(Restaurant) offerTags;
  final double? userLat;
  final double? userLon;

  const _BestOfferCard({
    required this.restaurant,
    required this.kmToMiles,
    required this.offerTags,
    this.userLat,
    this.userLon,
  });

  static const List<Color> buddyGradient = [
    Color(0xFFFF2D83),
    Color(0xFF7C3AED),
    Color(0xFFFF7A00),
    Color(0xFFFFB100),
  ];

  @override
  Widget build(BuildContext context) {
    final tags = offerTags(restaurant);
    final dist = restaurant.distanceMiles ?? kmToMiles(restaurant.distance);

    return GestureDetector(
      onTap: () {
        final slug = restaurant.slug ?? restaurant.id;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsPage(
              slug: slug,
              latitude: userLat,
              longitude: userLon,
            ),
          ),
        );
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: restaurant.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.black.withOpacity(0.03),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.black.withOpacity(0.03),
                        child: const Icon(
                          Icons.restaurant,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    if (tags.isNotEmpty)
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: buddyGradient,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            tags.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (restaurant.leaderboardScore > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.stars,
                                size: 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.leaderboardScore.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${restaurant.rating.toStringAsFixed(1)} (${restaurant.reviewCount}) • ${dist.toStringAsFixed(2)} miles • ${restaurant.cuisine}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (tags.length > 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.skip(1).take(2).map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              foreground: Paint()
                                ..shader =
                                    const LinearGradient(
                                      colors: buddyGradient,
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 140, 20),
                                    ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  final Restaurant restaurant;
  final double Function(double) kmToMiles;
  final List<String> Function(Restaurant) offerTags;
  final double? userLat;
  final double? userLon;

  const _FeedTile({
    required this.restaurant,
    required this.kmToMiles,
    required this.offerTags,
    this.userLat,
    this.userLon,
  });

  static const List<Color> buddyGradient = [
    Color(0xFFFF2D83),
    Color(0xFF7C3AED),
    Color(0xFFFF7A00),
    Color(0xFFFFB100),
  ];

  @override
  Widget build(BuildContext context) {
    final tags = offerTags(restaurant);
    final dist = restaurant.distanceMiles ?? kmToMiles(restaurant.distance);

    return GestureDetector(
      onTap: () {
        final slug = restaurant.slug ?? restaurant.id;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsPage(
              slug: slug,
              latitude: userLat,
              longitude: userLon,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: restaurant.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.black.withOpacity(0.03),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black.withOpacity(0.03),
                    child: const Icon(
                      Icons.restaurant,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (restaurant.leaderboardScore > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.stars,
                                size: 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.leaderboardScore.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${restaurant.rating.toStringAsFixed(1)} (${restaurant.reviewCount}) • ${dist.toStringAsFixed(2)} miles • ${restaurant.cuisine}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.take(3).map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              foreground: Paint()
                                ..shader =
                                    const LinearGradient(
                                      colors: buddyGradient,
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 140, 20),
                                    ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
