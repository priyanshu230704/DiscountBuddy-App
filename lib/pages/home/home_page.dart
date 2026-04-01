import 'dart:async';
import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_gradient_button.dart';

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

  double? _userLatitude;
  double? _userLongitude;

  HomeFilter? _activeFilter = HomeFilter.offers;

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
      // If we are currently on fallback or no location, try to get real location
      if (_userLatitude == null || _userLongitude == null) {
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
      debugPrint('📍 Still no location after settings, proceeding without it');
      if (mounted) {
        setState(() {
          _userLatitude = null;
          _userLongitude = null;
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
        setState(() {
          _cityName = 'Location Off';
          _userLatitude = null;
          _userLongitude = null;
        });
        _promptToEnableLocation(
          'Location services are off.',
          isServiceOff: true,
        );
      }
    } on LocationPermissionDeniedException {
      debugPrint('📍 Location permission denied');
      if (mounted) {
        setState(() {
          _cityName = 'No Permission';
          _userLatitude = null;
          _userLongitude = null;
        });
        _promptToEnableLocation(
          'Location permission denied.',
          isServiceOff: false,
        );
      }
    } catch (e) {
      debugPrint('📍 Location unavailable: $e');
      if (mounted) {
        setState(() {
          _userLatitude = null;
          _userLongitude = null;
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        margin: const EdgeInsets.all(AppSpacing.lg),
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
          latitude: _userLatitude ?? 51.5074,
          longitude: _userLongitude ?? -0.1278,
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
      child: AppScaffold(
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
      backgroundColor: const Color(0xFFF3E8FF), // Opaque to hide content scrolling underneath
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      collapsedHeight: _isSearching ? 112 + topPadding : 30 + topPadding,
      expandedHeight: _isSearching ? 112 + topPadding : 30 + topPadding,
      stretch: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFFF3E8FF),
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
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            "assets/png/db_logo.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Discount",
                                style: AppTypography.title.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  color: const Color(0xFF1B1436),
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Buddy",
                                style: AppTypography.title.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  color: const Color(0xFF8B5CF6),
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Location selector
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
                                  _cityName = city.name;
                                  _userLatitude = city.latitude;
                                  _userLongitude = city.longitude;
                                });
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
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
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
                                color: AppColors.textPrimary,
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 100,
          child: const _GradientBanner(
            title: "Get the Best Restaurant Deals",
            subtitle: "",
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
            final double maxWidth = constraints.maxWidth.isFinite 
                ? constraints.maxWidth 
                : MediaQuery.of(context).size.width - 32;
            const gap = 10.0;
            final chipWidth = (maxWidth - (gap * 2)) / 3;
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
          style: AppTypography.title.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
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
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
        color: AppColors.surface,
        borderRadius: AppRadius.xLarge,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
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
                hintStyle: AppTypography.body.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
              ),
              style: AppTypography.body.copyWith(
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
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          height: 42,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: active ? AppColors.purpleGradient : null,
            color: active ? null : AppColors.surface,
            border: active
                ? null
                : Border.all(color: AppColors.cardBorder),
            boxShadow: [
              if (active)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                ...AppShadows.card,
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
                  style: AppTypography.body.copyWith(
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
        gradient: AppColors.purpleGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTypography.title.copyWith(
                          fontSize: 16,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Savor the Savings, Every Day",
                        style: AppTypography.body.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(flex: 40, child: SizedBox()),
              ],
            ),
          ),

          // Food Image on right
          Positioned(
            right: 0,
            top: 10,
            bottom: 10,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(50),
                bottomLeft: Radius.circular(50),
              ),
              child: Image.network(
                "https://images.unsplash.com/photo-1473093226795-af9932fe5856?q=80&w=400&auto=format&fit=crop",
                width: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  "assets/png/banner-sm.png",
                  width: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // "Live Deals" Badge
          Positioned(
            bottom: 8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.flash_on,
                    color: Color(0xFFF97316),
                    size: 11,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "LIVE DEALS",
                    style: AppTypography.title.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF97316),
                      letterSpacing: 0.4,
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

  Color _occupancyColor(String? occupancy) {
    switch (occupancy) {
      case 'very_busy':
        return const Color(0xFFEF4444);
      case 'moderately_busy':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _occupancyLabel(String? occupancy) {
    switch (occupancy) {
      case 'very_busy':
        return 'Very Busy';
      case 'moderately_busy':
        return 'Moderate';
      default:
        return 'Available';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dist = restaurant.distanceMiles ?? kmToMiles(restaurant.distance);
    final hasImage = restaurant.imageUrl.isNotEmpty;
    final hasOccupancy = restaurant.occupancy != null;
    final deals = restaurant.activeDeals.where((d) => d.type != 'none').toList();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsPage(
              slug: restaurant.id,
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top: Full-width Image with Deal Badge ---
            Stack(
              children: [
                // Full-width image
                SizedBox(
                  width: double.infinity,
                  height: 125,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: restaurant.imageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF3F4F6),
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
                              Icons.restaurant_rounded,
                              color: Color(0xFFD1D5DB),
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: Color(0xFFD1D5DB),
                            size: 40,
                          ),
                        ),
                ),

                // Bottom gradient scrim for readability
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Deal Badge (New Stacked Design) ---
                if (deals.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20), // Matches card rounding
                          bottomRight: Radius.circular(36),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deals.first.displayText.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            "Limited Time",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Occupancy badge on top-right
                if (hasOccupancy)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65), // Dark background for contrast
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _occupancyColor(restaurant.occupancy),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _occupancyLabel(restaurant.occupancy),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _occupancyColor(restaurant.occupancy),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // --- Bottom: Details ---
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row
                        Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),

                        // Rating row
                        Row(
                          children: [
                            if (restaurant.rating > 0) ...[
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFBBF24), size: 14),
                              const SizedBox(width: 2),
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              Text(
                                ' (${restaurant.reviewCount})',
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF9CA3AF)),
                              ),
                            ] else
                              const Text(
                                'New',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                          ],
                        ),

                        // Cuisine/City
                        if (restaurant.cuisine.isNotEmpty &&
                            restaurant.cuisine != 'Restaurant') ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.restaurant_menu_rounded,
                                  color: Color(0xFFB0B8C5), size: 11),
                              const SizedBox(width: 3),
                              Text(
                                restaurant.cuisine,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Right Side: Distance and Reserve Button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Color(0xFF8B5CF6), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${dist.toStringAsFixed(1)} mi',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppGradientButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailsPage(
                                slug: restaurant.id,
                                latitude: userLat,
                                longitude: userLon,
                              ),
                            ),
                          );
                        },
                        height: 36,
                        width: 92,
                        borderRadius: BorderRadius.circular(12),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: Colors.white, size: 13),
                            SizedBox(width: 6),
                            Text(
                              'Reserve',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _DealCarousel extends StatefulWidget {
  final List<Discount> deals;
  const _DealCarousel({required this.deals});

  @override
  _DealCarouselState createState() => _DealCarouselState();
}

class _DealCarouselState extends State<_DealCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.deals.length > 1) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= widget.deals.length) {
          _currentPage = 0;
          _pageController.jumpToPage(0);
        } else {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deals.isEmpty) return const SizedBox.shrink();
    if (widget.deals.length == 1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [_buildDealBadge(widget.deals[0])],
      );
    }

    return SizedBox(
      height: 22,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.deals.length,
        itemBuilder: (context, index) {
          return Align(
            alignment: Alignment.centerLeft,
            child: _buildDealBadge(widget.deals[index]),
          );
        },
      ),
    );
  }

  Widget _buildDealBadge(Discount deal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEF4444)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        deal.displayText,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
