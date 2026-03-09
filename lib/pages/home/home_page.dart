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
import '../../theme/app_colors.dart';

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

  bool _isLoading = true;
  bool _isSearching = false;

  String _cityName = 'Detecting...';
  int _notificationCount = 0;
  StreamSubscription<RemoteMessage>? _notificationSubscription;

  double _userLatitude = 0;
  double _userLongitude = 0;

  HomeFilter? _activeFilter = HomeFilter.offers;

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

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
    if (!mounted) return;
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredRestaurants = _applyFilter(_restaurants);
      } else {
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
    if (!mounted) return;
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
                if (restaurantId != null) {
                  cuisineMap[restaurantId] = cuisineName;
                }
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
          _nearbyRestaurants = restaurants;
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
    if (desc.contains('drink') || desc.contains('soft drink')) {
      tags.add("FREE Drink");
    }
    if (desc.contains('side')) tags.add("FREE Side");

    return tags;
  }

  List<Restaurant> _applyFilter(List<Restaurant> list) {
    if (_activeFilter == HomeFilter.nearest) {
      // For Best Near You, always map to the nearby list instead
      final copy = [..._nearbyRestaurants];
      copy.sort((a, b) => b.leaderboardScore.compareTo(a.leaderboardScore));
      return copy;
    }

    final copy = [...list];

    switch (_activeFilter) {
      case HomeFilter.offers: // Now acts as All Restaurants
        copy.sort((a, b) => b.leaderboardScore.compareTo(a.leaderboardScore));
        return copy;
      case HomeFilter.rating: // Top Rated
        copy.sort((a, b) {
          int ratingComparison = b.rating.compareTo(a.rating);
          if (ratingComparison != 0) return ratingComparison;
          return b.reviewCount.compareTo(a.reviewCount);
        });
        return copy;
      case HomeFilter.openNow:
        return copy;
      default:
        return copy;
    }
  }

  void _toggleFilter(HomeFilter filter) {
    setState(() {
      _activeFilter = filter; // Prevent unselecting
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
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _searchController.clear();
          _searchFocusNode.unfocus();
          setState(() => _isSearching = false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        body: RefreshIndicator(
          onRefresh: _loadRestaurants,
          color: AppColors.discount,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            cacheExtent: 1200,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              _buildHeader(),
              if (!_isSearching) _buildBanners(),
              if (!_isSearching) _buildFilterTabs(),
              if (!_isSearching) _buildSectionTitle(),
              _buildRestaurantFeed(list),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final double topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      collapsedHeight: _isSearching ? 112 + topPadding : 70 + topPadding,
      expandedHeight: _isSearching ? 112 + topPadding : 70 + topPadding,
      stretch: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF3E8FF), Colors.white], // Soft purple to white
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            "assets/png/db_logo.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Discount",
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                                color: const Color(0xFF1B1436),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Buddy",
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                                color: const Color(0xFF8B5CF6),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Location selector
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
                                setState(() => _cityName = city.name);
                                _loadRestaurants();
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF8B5CF6),
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _cityName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Notification Icon
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsPage(),
                            ),
                          );
                          _loadNotificationCount();
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.04),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.notifications_none,
                                size: 21,
                                color: textPrimary,
                              ),
                            ),
                            if (_notificationCount > 0)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isSearching) ...[
                    const SizedBox(height: 16),
                    _SearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onClose: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        setState(() => _isSearching = false);
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 0),
                  ],
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
        padding: const EdgeInsets.only(top: 0, bottom: 6),
        child: SizedBox(
          height: 200,
          child: const _GradientBanner(
            title: "Get the Best Restaurant Deals",
            subtitle: "Exclusive offers and table\nreservations in your city.",
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final chipWidth = (constraints.maxWidth - (gap * 2)) / 3;
            return Row(
              children: [
                SizedBox(
                  width: chipWidth,
                  child: _FilterChipX(
                    text: "All Restaurants",
                    active: _activeFilter == HomeFilter.offers,
                    onTap: () => _toggleFilter(HomeFilter.offers),
                  ),
                ),
                const SizedBox(width: gap),
                SizedBox(
                  width: chipWidth,
                  child: _FilterChipX(
                    text: "Best Near You",
                    active: _activeFilter == HomeFilter.nearest,
                    onTap: () => _toggleFilter(HomeFilter.nearest),
                  ),
                ),
                const SizedBox(width: gap),
                SizedBox(
                  width: chipWidth,
                  child: _FilterChipX(
                    text: "Top Rated",
                    active: _activeFilter == HomeFilter.rating,
                    onTap: () => _toggleFilter(HomeFilter.rating),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Text(
          _activeFilter == HomeFilter.offers
              ? "All Restaurants"
              : _activeFilter == HomeFilter.nearest
              ? "Best Near You"
              : "Top Rated Restaurants",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantFeed(List<Restaurant> list) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.discount),
          ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
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

  @override
  Widget build(BuildContext context) {
    final Gradient bgGradient = const LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          height: 42,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: active ? bgGradient : null,
            color: active ? null : Colors.white,
            border: active
                ? null
                : Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              if (active)
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ],
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

  const _GradientBanner({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFD946EF), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Background Glow effect
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  flex: 55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 18),
                      // Explore Now Button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          "Explore Now",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(flex: 45, child: SizedBox()),
              ],
            ),
          ),

          // Food Image on right
          Positioned(
            right: 0,
            top: 20,
            bottom: 20,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(80),
                bottomLeft: Radius.circular(80),
              ),
              child: Image.network(
                "https://images.unsplash.com/photo-1473093226795-af9932fe5856?q=80&w=400&auto=format&fit=crop", // High-quality pasta image
                width: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  "assets/png/banner-sm.png",
                  width: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // "Live Deals" Badge
          Positioned(
            bottom: 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.flash_on,
                    color: Color(0xFFF97316),
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "LIVE DEALS",
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF97316),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    const double cardRadius = 28;
    const double imageHeight = 118;
    final tags = offerTags(restaurant);
    final dist = restaurant.distanceMiles ?? kmToMiles(restaurant.distance);
    final String discountText = tags.isNotEmpty ? tags.first : "30% OFF";
    final String numeric =
        discountText.replaceAll(RegExp(r'[^0-9]'), '').isEmpty
        ? '30'
        : discountText.replaceAll(RegExp(r'[^0-9]'), '');

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
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: restaurant.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    filterQuality: FilterQuality.low,
                    maxWidthDiskCache: 900,
                    maxHeightDiskCache: 600,
                    placeholder: (context, url) => Container(
                      color: Colors.black.withValues(alpha: 0.03),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(
                        Icons.restaurant,
                        color: Color(0xFFD1D5DB),
                        size: 40,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            discountText,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            "Limited Time",
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1B1436),
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            "Reserve a Table",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 14,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFBBF24),
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B1436),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Row(
                          children: List.generate(
                            3,
                            (index) => const Padding(
                              padding: EdgeInsets.only(right: 1),
                              child: Icon(
                                Icons.star,
                                color: Color(0xFFFCD34D),
                                size: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${restaurant.reviewCount} reviews",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 14,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Use code BUDDY$numeric to get ${discountText.toLowerCase()}",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4B5563),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF8B5CF6),
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "${dist.toStringAsFixed(1)} miles away",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4B5563),
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
      ),
    );
  }
}
