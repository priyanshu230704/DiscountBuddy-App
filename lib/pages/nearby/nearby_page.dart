import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../design/app_typography.dart';
import '../../models/restaurant.dart';
import '../../models/city.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../../services/city_service.dart';
import '../../design/app_colors.dart';
import '../../design/app_radius.dart';
import '../../design/app_shadows.dart';
import '../restaurant_details_page.dart';
import '../../widgets/city_selector_modal.dart';
import '../../widgets/filter_modal.dart';
import '../../widgets/generic_bottom_sheet.dart';
import '../../widgets/occupancy_tag.dart';

class NearbyPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const NearbyPage({super.key, this.initialLatitude, this.initialLongitude});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  final CityService _cityService = CityService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointManager;

  bool _isLoading = true;

  bool _isSearching = false;

  String _cityName = "Detecting...";

  Point? _center;
  Point? _userLocation;
  double _zoom = 13;
  int? _selectedCityId;

  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];

  List<Restaurant> _cityRestaurants = [];
  bool _isCityListLoading = false;

  Restaurant? _selectedRestaurant;
  String? _selectedRestaurantId;

  final Map<String, PointAnnotation> _restaurantPins = {};

  final Map<String, String> _annotationIdToRestaurantId = {};

  Uint8List? _pinNormalBytes;
  Uint8List? _pinSelectedBytes;
  Uint8List? _pinPopBytes;
  ui.Image? _appLogoImage;

  PointAnnotation? _userDotAnnotation;

  bool _isManualCitySelected = false;
  bool _isMarkerAnimating = false;

  bool _isProgrammaticMove = false;
  bool _isUserMovingMap = false;
  bool _isMapReady = false;

  static const int _pinNormalSize = 140;
  static const int _pinSelectedSize = 170;
  static const int _pinPopSize = 240;

  static const double _pinNormalIconSize = 1.25;
  static const double _pinSelectedIconSize = 1.35;

  static const double _normalSortKey = 1;
  static const double _selectedSortKey = 9999;

  late AnimationController _cardController;
  late Animation<Offset> _cardSlide;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_filterRestaurants);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _cardSlide =
        Tween<Offset>(
          begin: const Offset(0, 0.22),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialCityAndData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialCityAndData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        final pt = Point(
          coordinates: Position(
            widget.initialLongitude!,
            widget.initialLatitude!,
          ),
        );
        setState(() {
          _center = pt;
          _zoom = 15;
          _isManualCitySelected = true;
        });

        // Background update user GPS for the blue dot
        _locationService
            .getCurrentLocation()
            .then((position) {
              if (mounted) {
                setState(() {
                  _userLocation = Point(
                    coordinates: Position(
                      position.longitude,
                      position.latitude,
                    ),
                  );
                });
              }
            })
            .catchError((_) {});
      } else {
        // Fast path: Get coordinates first
        final position = await _locationService.getCurrentLocation();
        if (!mounted) return;

        final userPt = Point(
          coordinates: Position(position.longitude, position.latitude),
        );

        if (!_isManualCitySelected) {
          setState(() {
            _center = userPt;
            _userLocation = userPt;
          });

          // Lazy path: Fetch city name AND sync with database ID
          try {
            final cityName = await _locationService.getCityName(
              position.latitude,
              position.longitude,
            );
            final cities = await _cityService.getCities();

            if (mounted && !_isManualCitySelected) {
              // Find matching city in our database list
              final matchedCity = cities.firstWhere(
                (c) =>
                    c.name.toLowerCase().contains(cityName.toLowerCase()) ||
                    cityName.toLowerCase().contains(c.name.toLowerCase()),
                orElse: () => cities.firstWhere(
                  (c) => c.id == 1,
                  orElse: () => cities.first,
                ),
              );

              setState(() {
                _cityName = matchedCity.name;
                _selectedCityId = matchedCity.id;
              });

              // Re-run restaurant load now that we have the proper city ID
              await _loadCityRestaurants();
            }
          } catch (_) {}
        }
      }

      await _loadCityRestaurants();
    } catch (_) {
      // Final fallback
      setState(() {
        _center ??= Point(coordinates: Position(-0.1278, 51.5074));
        _cityName = 'London';
      });
      await _loadCityRestaurants();
    }
  }

  Future<void> _loadCityRestaurants() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isCityListLoading = true;

      _selectedRestaurant = null;
      _selectedRestaurantId = null;
    });

    _cardController.reverse();

    try {
      final list = await _restaurantService.getRestaurants(
        cityId: _selectedCityId,
      );

      if (!mounted) return;

      setState(() {
        _cityRestaurants = list;
        _restaurants = list;
        _filteredRestaurants = list;

        _isLoading = false;
        _isCityListLoading = false;
      });

      await _ensureMarkerBytes();
      await _syncPinsWithList();
      await _moveCameraToCenter();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cityRestaurants = [];
        _restaurants = [];
        _filteredRestaurants = [];

        _isLoading = false;
        _isCityListLoading = false;
      });

      await _syncPinsWithList();
    }
  }

  Future<void> _moveCameraToCenter() async {
    if (_mapboxMap == null) return;

    _isProgrammaticMove = true;

    await _mapboxMap!.flyTo(
      CameraOptions(center: _center!, zoom: 13),
      MapAnimationOptions(duration: 650),
    );

    await Future.delayed(const Duration(milliseconds: 700));
    _isProgrammaticMove = false;
  }

  Future<void> _centerMapOnLocation() async {
    if (_mapboxMap == null) return;

    try {
      final location = await _locationService.getUserLocation();
      if (!mounted) return;

      final userPoint = Point(
        coordinates: Position(
          location.position.longitude,
          location.position.latitude,
        ),
      );

      setState(() {
        _cityName = location.cityName;
        _center = userPoint;
        _selectedCityId = null; // Reset ID when using GPS location
      });

      _isProgrammaticMove = true;

      await _mapboxMap!.flyTo(
        CameraOptions(center: userPoint, zoom: 15),
        MapAnimationOptions(duration: 650),
      );

      await Future.delayed(const Duration(milliseconds: 700));
      _isProgrammaticMove = false;
    } catch (_) {
      // If location fetch fails, just fly to existing center
      if (_center == null) return;
      _isProgrammaticMove = true;
      await _mapboxMap!.flyTo(
        CameraOptions(center: _center!, zoom: 15),
        MapAnimationOptions(duration: 650),
      );
      await Future.delayed(const Duration(milliseconds: 700));
      _isProgrammaticMove = false;
    }
  }

  Future<void> _moveToRestaurant(Restaurant r) async {
    if (_mapboxMap == null) return;

    _isProgrammaticMove = true;

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(r.longitude, r.latitude)),
        zoom: _zoom < 14 ? 14 : _zoom,
      ),
      MapAnimationOptions(duration: 650),
    );

    await Future.delayed(const Duration(milliseconds: 700));
    _isProgrammaticMove = false;
  }

  void _filterRestaurants() async {
    final q = _searchController.text.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        _filteredRestaurants = _restaurants;
      } else {
        _filteredRestaurants = _restaurants.where((r) {
          return r.name.toLowerCase().contains(q) ||
              r.cuisine.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q);
        }).toList();
      }
    });

    await _syncPinsWithList();
  }

  double _kmToMiles(double km) => km * 0.621371;

  void _openRestaurant(Restaurant restaurant) {
    if (_center == null) return;
    final slug = restaurant.slug ?? restaurant.id;
    final lat = _center!.coordinates.lat.toDouble();
    final lon = _center!.coordinates.lng.toDouble();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RestaurantDetailsPage(slug: slug, latitude: lat, longitude: lon),
      ),
    );
  }

  List<String> _getOfferTags(Restaurant restaurant) {
    final tags = <String>[];
    final desc = restaurant.discount.description.toLowerCase();

    switch (restaurant.discount.type) {
      case '2for1':
        if (desc.contains("waffle")) {
          tags.add("2for1 Waffle");
        } else if (desc.contains("milkshake")) {
          tags.add("2for1 Milkshake");
        } else {
          tags.add("2for1 Deal");
        }
        break;

      case 'percentage':
        tags.add("${restaurant.discount.percentage?.toInt()}% Off");
        break;

      case 'fixed':
        tags.add("£${restaurant.discount.fixedAmount?.toStringAsFixed(0)} Off");
        break;
    }

    if (desc.contains("dessert")) tags.add("FREE Dessert");
    if (desc.contains("drink")) tags.add("FREE Drink");

    return tags.take(2).toList();
  }

  Future<void> _setupOrnaments() async {
    if (_mapboxMap == null) return;

    await _mapboxMap!.compass.updateSettings(CompassSettings(enabled: false));
    await _mapboxMap!.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    await _mapboxMap!.logo.updateSettings(LogoSettings(enabled: false));

    await _mapboxMap!.attribution.updateSettings(
      AttributionSettings(enabled: false),
    );
  }

  Future<Uint8List> _createDropPinMarkerBytes({
    required int size,
    required bool selected,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final double s = size.toDouble();
    final Offset topCenter = Offset(s / 2, s * 0.38);

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: selected ? 0.35 : 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(topCenter.dx, topCenter.dy + s * 0.55),
        width: s * 0.45,
        height: s * 0.15,
      ),
      shadowPaint,
    );

    final double topRadius = s * 0.28;
    final path = Path();

    path.addOval(Rect.fromCircle(center: topCenter, radius: topRadius));

    final Offset p1 = Offset(
      topCenter.dx - topRadius * 0.75,
      topCenter.dy + topRadius * 0.55,
    );
    final Offset p2 = Offset(
      topCenter.dx + topRadius * 0.75,
      topCenter.dy + topRadius * 0.55,
    );
    final Offset tip = Offset(topCenter.dx, topCenter.dy + topRadius * 2.20);

    path.moveTo(p1.dx, p1.dy);
    path.quadraticBezierTo(
      topCenter.dx,
      topCenter.dy + topRadius * 1.50,
      tip.dx,
      tip.dy,
    );
    path.quadraticBezierTo(
      topCenter.dx,
      topCenter.dy + topRadius * 1.50,
      p2.dx,
      p2.dy,
    );
    path.close();

    // Pin Body (Blue for selected, White for unselected)
    final fillPaint = Paint()
      ..color = selected ? AppColors.primaryPurple : Colors.white;
    canvas.drawPath(path, fillPaint);

    // Subtle stroke border
    final borderPaint = Paint()
      ..color = selected ? Colors.white : Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025;
    canvas.drawPath(path, borderPaint);

    // Draw the white inner circle
    final innerCirclePaint = Paint()
      ..color = selected ? Colors.white : const Color(0xFFF8F9FC);
    canvas.drawCircle(topCenter, topRadius * 0.95, innerCirclePaint);

    // Draw the actual db_logo.png app logo inside the pin
    if (_appLogoImage != null) {
      final double logoSize = topRadius * 1.55;
      final Rect destRect = Rect.fromCenter(
        center: topCenter,
        width: logoSize,
        height: logoSize,
      );
      final Rect srcRect = Rect.fromLTWH(
        0,
        0,
        _appLogoImage!.width.toDouble(),
        _appLogoImage!.height.toDouble(),
      );
      canvas.drawImageRect(
        _appLogoImage!,
        srcRect,
        destRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  Future<void> _ensureMarkerBytes() async {
    if (_appLogoImage == null) {
      final ByteData data = await rootBundle.load('assets/png/db_logo.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      _appLogoImage = fi.image;
    }

    _pinNormalBytes ??= await _createDropPinMarkerBytes(
      size: _pinNormalSize,
      selected: false,
    );

    _pinSelectedBytes ??= await _createDropPinMarkerBytes(
      size: _pinSelectedSize,
      selected: true,
    );

    _pinPopBytes ??= await _createDropPinMarkerBytes(
      size: _pinPopSize,
      selected: true,
    );
  }

  Future<Uint8List> _createUserDotBytes() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double size = 46;
    final center = const Offset(size / 2, size / 2);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center.translate(0, 4), size * 0.30, shadowPaint);

    final borderPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, size * 0.24, borderPaint);

    final fillPaint = Paint()..color = AppColors.primaryPurple;
    canvas.drawCircle(center, size * 0.16, fillPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  Future<void> _syncPinsWithList() async {
    if (_pointManager == null) return;

    await _ensureMarkerBytes();

    // Only show user dot if we have a real GPS location
    if (_userLocation != null) {
      final userDot = await _createUserDotBytes();
      if (_userDotAnnotation == null) {
        _userDotAnnotation = await _pointManager!.create(
          PointAnnotationOptions(
            geometry: _userLocation!,
            image: userDot,
            iconSize: 1.0,
          ),
        );
      } else {
        _userDotAnnotation!.geometry = _userLocation!;
        await _pointManager!.update(_userDotAnnotation!);
      }
    }

    final existingIds = _restaurantPins.keys.toSet();
    final requiredIds = _filteredRestaurants.map((e) => e.id).toSet();

    for (final id in existingIds.difference(requiredIds)) {
      final ann = _restaurantPins[id];
      if (ann != null) await _pointManager!.delete(ann);
      _restaurantPins.remove(id);
      _annotationIdToRestaurantId.removeWhere((key, value) => value == id);
    }

    for (final r in _filteredRestaurants) {
      if (_restaurantPins.containsKey(r.id)) continue;

      final bool isSelected = r.id == _selectedRestaurantId;

      final ann = await _pointManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(r.longitude, r.latitude)),
          image: isSelected ? _pinSelectedBytes! : _pinNormalBytes!,
          iconSize: isSelected ? _pinSelectedIconSize : _pinNormalIconSize,
          symbolSortKey: isSelected ? _selectedSortKey : _normalSortKey,
        ),
      );

      _restaurantPins[r.id] = ann;
      _annotationIdToRestaurantId[ann.id] = r.id;
    }

    await _refreshPinsStateOnly();
  }

  Future<void> _refreshPinsStateOnly() async {
    if (_pointManager == null) return;

    for (final r in _filteredRestaurants) {
      final ann = _restaurantPins[r.id];
      if (ann == null) continue;

      final bool isSelected = r.id == _selectedRestaurantId;

      ann.image = isSelected ? _pinSelectedBytes! : _pinNormalBytes!;
      ann.iconSize = isSelected ? _pinSelectedIconSize : _pinNormalIconSize;
      ann.symbolSortKey = isSelected ? _selectedSortKey : _normalSortKey;

      await _pointManager!.update(ann);
    }
  }

  Future<void> _bounceSelectedMarker(String id) async {
    if (_pointManager == null) return;
    if (_isMarkerAnimating) return;

    final ann = _restaurantPins[id];
    if (ann == null) return;

    _isMarkerAnimating = true;

    ann.image = _pinPopBytes!;
    ann.iconSize = 1.55;
    ann.symbolSortKey = _selectedSortKey;
    await _pointManager!.update(ann);
    await Future.delayed(const Duration(milliseconds: 120));

    ann.image = _pinSelectedBytes!;
    ann.iconSize = _pinSelectedIconSize;
    await _pointManager!.update(ann);
    await Future.delayed(const Duration(milliseconds: 90));

    ann.image = _pinPopBytes!;
    ann.iconSize = 1.55;
    await _pointManager!.update(ann);
    await Future.delayed(const Duration(milliseconds: 85));

    ann.image = _pinSelectedBytes!;
    ann.iconSize = _pinSelectedIconSize;
    await _pointManager!.update(ann);

    _isMarkerAnimating = false;
  }

  void _showRestaurantListModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return GenericBottomSheet(
              title: "Restaurants in $_cityName",
              onClose: () => Navigator.pop(context),
              expandChild: true,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _isCityListLoading
                            ? "Loading..."
                            : "${_cityRestaurants.length} places",
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _isCityListLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _cityRestaurants.isEmpty
                        ? Center(
                            child: Text(
                              "No restaurants found in $_cityName 😕",
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                            itemCount: _cityRestaurants.length,
                            itemBuilder: (context, index) {
                              final r = _cityRestaurants[index];

                              return GestureDetector(
                                onTap: () async {
                                  Navigator.pop(context);

                                  setState(() {
                                    _selectedRestaurant = r;
                                    _selectedRestaurantId = r.id;
                                  });

                                  _cardController.forward(from: 0);

                                  await _syncPinsWithList();
                                  await _refreshPinsStateOnly();
                                  await _bounceSelectedMarker(r.id);
                                  await _moveToRestaurant(r);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: AppRadius.xLarge,
                                    border: Border.all(color: AppColors.cardBorder),
                                    boxShadow: AppShadows.card,
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: CachedNetworkImage(
                                          imageUrl: r.imageUrl,
                                          width: 62,
                                          height: 62,
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) => Container(
                                            width: 62,
                                            height: 62,
                                            color: Colors.grey.shade200,
                                          ),
                                          errorWidget: (_, _, _) => Container(
                                            width: 62,
                                            height: 62,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.restaurant),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.title.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _cityName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.bodySmall.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _center == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2F80ED)),
            )
          : Stack(
              children: [
                MapWidget(
                  key: const ValueKey("mapWidget"),
                  cameraOptions: CameraOptions(center: _center!, zoom: _zoom),
                  styleUri: MapboxStyles.LIGHT,
                  onMapCreated: (mapboxMap) async {
                    _mapboxMap = mapboxMap;

                    if (mounted) {
                      setState(() => _isMapReady = true);
                    }

                    _pointManager = await _mapboxMap!.annotations
                        .createPointAnnotationManager();

                    await _ensureMarkerBytes();
                    await _syncPinsWithList();

                    await Future.delayed(const Duration(milliseconds: 250));
                    await _setupOrnaments();

                    _pointManager!.tapEvents(
                      onTap: (ann) async {
                        if (_isMarkerAnimating) return;

                        final restaurantId =
                            _annotationIdToRestaurantId[ann.id];
                        if (restaurantId == null) return;

                        final selected = _filteredRestaurants.firstWhere(
                          (r) => r.id == restaurantId,
                          orElse: () => _filteredRestaurants.first,
                        );

                        setState(() {
                          _selectedRestaurant = selected;
                          _selectedRestaurantId = selected.id;
                        });

                        _cardController.forward(from: 0);

                        await _refreshPinsStateOnly();
                        await _bounceSelectedMarker(selected.id);
                        await _moveToRestaurant(selected);
                      },
                    );
                  },

                  onTapListener: (_) async {
                    setState(() {
                      _selectedRestaurant = null;
                      _selectedRestaurantId = null;
                    });
                    _cardController.reverse();
                    await _refreshPinsStateOnly();
                  },

                  onCameraChangeListener: (_) async {
                    if (_mapboxMap == null) return;

                    final cam = await _mapboxMap!.getCameraState();
                    _zoom = cam.zoom;

                    if (_isProgrammaticMove) return;

                    if (_selectedRestaurant != null && !_isUserMovingMap) {
                      _isUserMovingMap = true;

                      setState(() {
                        _selectedRestaurant = null;
                        _selectedRestaurantId = null;
                      });

                      _cardController.reverse();
                      await _refreshPinsStateOnly();

                      Future.delayed(const Duration(milliseconds: 350), () {
                        _isUserMovingMap = false;
                      });
                    }

                    // Update center
                    _center = cam.center;
                  },
                ),

                if (!_isMapReady)
                  Container(
                    color: AppColors.background,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2F80ED),
                      ),
                    ),
                  ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: _isSearching ? _searchTopBar() : _normalTopBar(),
                  ),
                ),

                if (_selectedRestaurant != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom:
                        125, // Adjusted to prevent touching bottom navigation bar
                    child: SlideTransition(
                      position: _cardSlide,
                      child: _restaurantPreviewCard(_selectedRestaurant!),
                    ),
                  ),

                if (_selectedRestaurant == null && !_isSearching)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom:
                        135, // Adjusted to prevent touching bottom navigation bar
                    child: _bottomButtons(),
                  ),

                if (_isLoading)
                  Positioned(
                    top: 95,
                    left: 16,
                    right: 16,
                    child: _loadingPill(),
                  ),
              ],
            ),
    );
  }

  Widget _normalTopBar() {
    final w = MediaQuery.of(context).size.width;
    final cityFontSize = w < 370 ? 24.0 : 30.0;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: false,
                backgroundColor: Colors.transparent,
                builder: (context) => CitySelectorModal(
                  selectedCity: _cityName,
                  onCitySelected: (City city) async {
                    _isManualCitySelected = true;

                    setState(() {
                      _cityName = city.name;
                      _selectedCityId = city.id;

                      _center = Point(
                        coordinates: Position(city.longitude, city.latitude),
                      );

                      _selectedRestaurant = null;
                      _selectedRestaurantId = null;
                    });

                    _cardController.reverse();

                    await _moveCameraToCenter();
                    await _loadCityRestaurants();
                  },
                ),
              );
            },
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _cityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline.copyWith(
                      fontSize: cityFontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, size: 32),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () {
            setState(() => _isSearching = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _searchFocusNode.requestFocus();
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.all(6.0),
            child: Icon(Icons.search, size: 28, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _searchTopBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, size: 26, color: Colors.black),
          onPressed: () {
            _searchController.clear();
            _searchFocusNode.unfocus();
            setState(() => _isSearching = false);
          },
        ),
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: Colors.black54),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search restaurants...",
                    ),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () => _searchController.clear(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomButtons() {
    return Row(
      children: [
        Expanded(
          child: _bottomPillButton(
            icon: Icons.filter_alt_outlined,
            label: "Filter",
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useSafeArea: true,
                builder: (_) => FilterModal(
                  onApply: (filters) {
                    debugPrint("Filters applied: $filters");
                    _loadCityRestaurants();
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _bottomPillButton(
            icon: Icons.list,
            label: "List",
            onTap: _showRestaurantListModal,
          ),
        ),
        const SizedBox(width: 12),
        _gpsCircleButton(),
      ],
    );
  }

  Widget _bottomPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.button.copyWith(
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gpsCircleButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _centerMapOnLocation,
          borderRadius: BorderRadius.circular(60),
          child: const Icon(Icons.navigation, size: 20, color: Colors.black),
        ),
      ),
    );
  }

  Widget _restaurantPreviewCard(Restaurant restaurant) {
    final dist = restaurant.distanceMiles ?? _kmToMiles(restaurant.distance);
    final tags = _getOfferTags(restaurant);

    return GestureDetector(
      onTap: () => _openRestaurant(restaurant),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.98),
          borderRadius: AppRadius.xLarge,
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: restaurant.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, _, _) => Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.restaurant),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: AppTypography.title.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OccupancyTag(
                        occupancy: restaurant.occupancy,
                        isSmall: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 18,
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${restaurant.rating.toStringAsFixed(1)} (${restaurant.reviewCount})",
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${dist.toStringAsFixed(2)} miles",
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          restaurant.cuisine,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          t,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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

  Widget _loadingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            "Loading nearby restaurants...",
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
