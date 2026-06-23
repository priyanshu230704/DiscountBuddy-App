import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import 'package:get/get.dart';

import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../../services/app_config_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/city_selector_modal.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_gradient_button.dart';
import '../../utils/distance_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum HomeFilter { offers, rating, nearest, openNow }

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  final AuthProvider _authProvider = AuthProvider();
  final AppConfigService _appConfigService = AppConfigService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Restaurant> _restaurants = [];
  List<Restaurant> _nearbyRestaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  List<Map<String, dynamic>> _banners = [];

  bool _isLoading = true;
  bool _isSearching = false;

  String _cityName = 'Detecting...';
  int _currentBannerIndex = 0;
  // Removed local _notificationCount and _notificationSubscription as it's now handled by NotificationProvider and FirebaseMessagingService
  final NotificationProvider _notificationProvider = NotificationProvider();

  double? _userLatitude;
  double? _userLongitude;

  bool _locationPermissionDenied = false;
  bool _isFetchingLocation = false;
  bool _isLoadingRestaurants = false;

  HomeFilter? _activeFilter = HomeFilter.offers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocationAndLoadData();
    // Defer: fetchUnreadCount() notifies listeners; cannot run during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notificationProvider.fetchUnreadCount(false);
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationProvider.fetchUnreadCount(false);

      // Only retry location if permission was not explicitly denied this session.
      // Avoids API loop when user taps "Don't allow" and the app resumes.
      if (!_locationPermissionDenied &&
          (_userLatitude == null || _userLongitude == null)) {
        _tryRefreshLocationFromSettings();
      }
    }
  }

  /// Re-check permission after user may have changed it in Settings (no auto-prompt).
  Future<void> _tryRefreshLocationFromSettings() async {
    if (_isFetchingLocation || !mounted) return;

    final permission = await _locationService.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationPermissionDenied = true;
          _cityName = permission == LocationPermission.deniedForever
              ? 'Permission blocked'
              : 'No Permission';
        });
      }
      return;
    }

    _isFetchingLocation = true;
    try {
      final location = await _locationService.getUserLocation();
      if (!mounted) return;
      setState(() {
        _locationPermissionDenied = false;
        _userLatitude = location.position.latitude;
        _userLongitude = location.position.longitude;
        _cityName = location.cityName;
      });
      await _loadRestaurants();
    } catch (e) {
      debugPrint('📍 Location refresh skipped: $e');
    } finally {
      _isFetchingLocation = false;
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
    if (_isFetchingLocation) return;
    _isFetchingLocation = true;

    try {
      final location = await _locationService.getUserLocation(
        requestPermissionIfDenied: true,
      );
      if (mounted) {
        setState(() {
          _locationPermissionDenied = false;
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
    } on LocationPermissionDeniedException catch (e) {
      debugPrint('📍 Location permission denied (permanent: ${e.isPermanent})');
      if (mounted) {
        setState(() {
          _locationPermissionDenied = true;
          _cityName = e.isPermanent ? 'Permission blocked' : 'No Permission';
          _userLatitude = null;
          _userLongitude = null;
        });
        _promptToEnableLocation(
          e.isPermanent
              ? 'Location access is blocked. Enable it in Settings to see nearby deals.'
              : 'Location permission denied. Enable it in Settings for nearby deals.',
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
      _isFetchingLocation = false;
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

  // Removed local _loadNotificationCount as it's now in NotificationProvider

  Future<void> _loadRestaurants() async {
    if (!mounted || _isLoadingRestaurants) return;
    _isLoadingRestaurants = true;
    setState(() => _isLoading = true);

    try {
      try {
        final bannersData = await _appConfigService.getBanners();
        final visibleBanners = bannersData
            .where((b) => b['is_visible'] == true)
            .toList();
        visibleBanners.sort(
          (a, b) => (a['priority'] as int? ?? 0).compareTo(
            b['priority'] as int? ?? 0,
          ),
        );
        _banners = visibleBanners;
      } catch (e) {
        debugPrint('Failed to load banners: $e');
      }

      if (_authProvider.isCustomer) {
        final homeData = await _restaurantService.getHomeData(
          latitude: _userLatitude,
          longitude: _userLongitude,
        );

        // Normalize maps from new structure
        final Map<String, dynamic> restaurantsData =
            homeData['restaurants'] as Map<String, dynamic>? ?? {};
        final Map<String, dynamic> dealsData =
            homeData['deals'] as Map<String, dynamic>? ?? {};
        final Map<String, dynamic> cuisinesData =
            homeData['cuisines'] as Map<String, dynamic>? ?? {};
        final Map<String, dynamic> sections =
            homeData['sections'] as Map<String, dynamic>? ?? {};

        final Map<int, String> cuisineMap = {};
        cuisinesData.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final id = value['id'] as int?;
            final name = value['name'] as String?;
            if (id != null && name != null) {
              cuisineMap[id] = name;
            }
          }
        });

        // Helper to convert normalized restaurant to model
        Restaurant parseRestaurant(int id) {
          final json = restaurantsData[id.toString()] as Map<String, dynamic>?;
          if (json == null) {
            return _restaurantService.convertApiRestaurantToModel({'id': id});
          }

          final List<dynamic> cuisineIds =
              json['cuisines'] as List<dynamic>? ?? [];
          final List<dynamic> dealIds = json['deals'] as List<dynamic>? ?? [];

          // Resolve ALL cuisine names
          List<String> cuisineNameList = [];
          for (final cId in cuisineIds) {
            final name = cuisineMap[cId as int];
            if (name != null) cuisineNameList.add(name);
          }
          String resolvedCuisine = 'Restaurant';
          if (cuisineNameList.isNotEmpty) {
            if (cuisineNameList.length > 3) {
              resolvedCuisine =
                  '${cuisineNameList.take(3).join(' • ')} & many more';
            } else {
              resolvedCuisine = cuisineNameList.join(' • ');
            }
          }

          // Resolve deals
          final List<Map<String, dynamic>> inflatedDeals = [];
          for (final dId in dealIds) {
            final dealJson = dealsData[dId.toString()] as Map<String, dynamic>?;
            if (dealJson != null) {
              inflatedDeals.add(dealJson);
            }
          }

          // Merge into a format that convertApiRestaurantToModel understands
          final Map<String, dynamic> mergedJson = Map<String, dynamic>.from(
            json,
          );
          mergedJson['active_deals'] = inflatedDeals;

          return _restaurantService.convertApiRestaurantToModel(
            mergedJson,
            cuisineMap: {id: resolvedCuisine},
          );
        }

        // Parse sections
        final List<int> allIds = List<int>.from(
          sections['all_restaurants'] ??
              sections['top_10'] ??
              sections['featured'] ??
              (restaurantsData.keys
                  .map((k) => int.tryParse(k))
                  .whereType<int>()
                  .toList()),
        );
        final List<int> nearbyIds = List<int>.from(sections['nearby'] ?? []);

        final allRestaurants = allIds.map((id) => parseRestaurant(id)).toList();
        final nearbyRestaurants = nearbyIds
            .map((id) => parseRestaurant(id))
            .toList();

        // Sort by leaderboard score (highest first)
        allRestaurants.sort(
          (a, b) => b.leaderboardScore.compareTo(a.leaderboardScore),
        );
        nearbyRestaurants.sort(
          (a, b) => b.leaderboardScore.compareTo(a.leaderboardScore),
        );

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
    } catch (e) {
      debugPrint('❌ Error loading restaurants: $e');
      if (mounted) setState(() => _isLoading = false);
    } finally {
      _isLoadingRestaurants = false;
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
        if (restaurant.discount.fixedAmount != null) {
          tags.add(
            "£${restaurant.discount.fixedAmount!.toStringAsFixed(0)} OFF",
          );
        } else {
          tags.add(restaurant.discount.displayText);
        }
        break;
      case 'combo':
        tags.add(restaurant.discount.displayText);
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
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
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
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      backgroundColor: const Color(
        0xFFF3E8FF,
      ), // Opaque to hide content scrolling underneath
      automaticallyImplyLeading: false,
      toolbarHeight: 48,
      collapsedHeight: _isSearching ? 114 : 48,
      expandedHeight: _isSearching ? 114 : 48,
      stretch: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFFF3E8FF),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.asset(
                            "assets/png/db_logo.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
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
                                  fontWeight: FontWeight.w700,
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
                                  fontWeight: FontWeight.w700,
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
                                  fontWeight: FontWeight.w700,
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
                          await Get.toNamed(AppRoutes.notifications);
                          _notificationProvider.refreshCount(false);
                        },
                        child: ListenableBuilder(
                          listenable: _notificationProvider,
                          builder: (context, child) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
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
                                if (_notificationProvider.unreadCount > 0)
                                  Positioned(
                                    top: -3,
                                    right: -3,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _notificationProvider.unreadCount > 99
                                              ? '99+'
                                              : '${_notificationProvider.unreadCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
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
    if (_banners.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        children: [
          CarouselSlider(
            items: _banners.map((banner) {
              return _GradientBanner(
                title: banner['title'] as String? ?? '',
                subtitle: banner['body'] as String? ?? '',
                imageUrl: banner['image'] as String?,
              );
            }).toList(),
            options: CarouselOptions(
              height: 135,
              viewportFraction: 1.0,
              autoPlay: _banners.length > 1,
              autoPlayInterval: const Duration(seconds: 5),
              onPageChanged: (index, reason) {
                setState(() => _currentBannerIndex = index);
              },
            ),
          ),
          if (_banners.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _banners.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(
                        alpha: _currentBannerIndex == entry.key ? 0.9 : 0.2,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: _FilterChipX(
                text: "All",
                active: _activeFilter == HomeFilter.offers,
                onTap: () => _toggleFilter(HomeFilter.offers),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterChipX(
                text: "Nearest",
                active: _activeFilter == HomeFilter.nearest,
                onTap: () => _toggleFilter(HomeFilter.nearest),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterChipX(
                text: "Top Rated",
                active: _activeFilter == HomeFilter.rating,
                onTap: () => _toggleFilter(HomeFilter.rating),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text(
          _activeFilter == HomeFilter.offers
              ? "All Restaurants"
              : _activeFilter == HomeFilter.nearest
              ? "Best Near You"
              : "Top Rated Restaurants",
          style: AppTypography.title.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
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
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
            child: Text(
              "No restaurants found 😅",
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
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
            padding: const EdgeInsets.only(bottom: 10),
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
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: active ? AppColors.purpleGradient : null,
          color: active ? null : Colors.white,
          border: Border.all(
            color: active ? Colors.transparent : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Text(
          text,
          style: AppTypography.body.copyWith(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF6B7280),
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _GradientBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;

  const _GradientBanner({
    required this.title,
    required this.subtitle,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.hardEdge,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorWidget: (context, url, error) => _buildTextBanner(context),
        ),
      );
    }

    return _buildTextBanner(context);
  }

  Widget _buildTextBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: AppColors.purpleGradient,
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Row(
              children: [
                Expanded(
                  flex: 65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't Eat Alone.\nShare the Deal\nwith Your Buddy.",
                        style: AppTypography.title.copyWith(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Less bill, more chill – Discount Buddy.",
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Expanded(flex: 35, child: SizedBox()),
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
                imageUrl ??
                    "https://images.unsplash.com/photo-1473093226795-af9932fe5856?q=80&w=400&auto=format&fit=crop",
                width: 130,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  "assets/png/banner-sm.png",
                  width: 130,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // "Live Deals" Badge
          Positioned(
            bottom: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
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
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "LIVE DEALS",
                    style: AppTypography.title.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF97316),
                      letterSpacing: 0.3,
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
        return 'Less Busy';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute pinpoint-accurate miles from user GPS + restaurant coordinates
    final miles = DistanceUtils.bestMiles(
      userLat: userLat,
      userLon: userLon,
      restaurantLat: restaurant.latitude,
      restaurantLon: restaurant.longitude,
      distanceMilesFromApi: restaurant.distanceMiles,
      distanceKmFromApi: restaurant.distance,
    );
    final hasImage = restaurant.imageUrl.isNotEmpty;
    final deals = restaurant.activeDeals
        .where((d) => d.type != 'none')
        .toList();

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.restaurantDetails,
          arguments: {
            'slug': restaurant.id,
            'latitude': userLat,
            'longitude': userLon,
          },
        );
      },
      child: Container(
        width: double.infinity,
        height: 188,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top: Full-width Image ---
            Stack(
              children: [
                // Full-width image
                SizedBox(
                  width: double.infinity,
                  height: 110, // Reduced so 2.5 cards fit in first view
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
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Top-Left Deal Badge ---
                if (deals.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                deals.first.displayText.toUpperCase(),
                                style: AppTypography.title.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.flash_on,
                                color: Colors.white,
                                size: 12,
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            (deals.first.shortDescription != null &&
                                    deals.first.shortDescription!.isNotEmpty)
                                ? deals.first.shortDescription!
                                : "Save today",
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                // --- Top-Right Occupancy Pill ---
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: _occupancyColor(restaurant.occupancy),
                          size: 8,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _occupancyLabel(restaurant.occupancy),
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Bottom-Left Rating on Image ---
                if (restaurant.rating > 0)
                  Positioned(
                    bottom: 10,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFBBF24),
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // --- Bottom: Details Area ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 3, 8, 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Left Side: Texts ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Restaurant Name
                          Text(
                            restaurant.name,
                            style: AppTypography.title.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Description below name
                          if (restaurant.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              restaurant.description.trim(),
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                color: const Color(0xFF6B7280),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          // Cuisines below description
                          if (restaurant.cuisine.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              restaurant.cuisine,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9CA3AF),
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          const SizedBox(height: 3),

                          // Value Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_offer_outlined,
                                  color: Color(0xFF059669),
                                  size: 9,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "££ • Great value",
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // --- Right Side: Distance & Reserve Button ---
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (miles != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF8B5CF6),
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${miles.toStringAsFixed(1)} mi',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        AppGradientButton(
                          onPressed: () {
                            Get.toNamed(
                              AppRoutes.restaurantDetails,
                              arguments: {
                                'slug': restaurant.id,
                                'latitude': userLat,
                                'longitude': userLon,
                              },
                            );
                          },
                          height: 32,
                          width: 80,
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Reserve',
                                style: AppTypography.button.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
        style: AppTypography.caption.copyWith(
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
