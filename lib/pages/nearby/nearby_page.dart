import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:discount_buddy/design/app_design.dart';
import '../../models/restaurant.dart';
import '../../models/city.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../../services/city_service.dart';
import '../restaurant_details_page.dart';
import '../../widgets/city_selector_modal.dart';
import '../../widgets/filter_modal.dart';
import '../../widgets/generic_bottom_sheet.dart';
import '../../widgets/occupancy_tag.dart';
import '../../widgets/app_scaffold.dart';
import '../../utils/distance_utils.dart';

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

  List<Restaurant> _filteredRestaurants = [];

  List<Restaurant> _cityRestaurants = [];
  bool _isCityListLoading = false;

  int? _selectedCuisineId;
  int? _selectedDay;
  String? _selectedTime;
  Timer? _debounce;

  Restaurant? _selectedRestaurant;
  String? _selectedRestaurantId;

  final Map<String, PointAnnotation> _restaurantPins = {};

  final Map<String, String> _annotationIdToRestaurantId = {};

  final Map<String, Uint8List> _markerCache = {};

  PointAnnotation? _userDotAnnotation;
  ui.Image? _appLogoImage;

  bool _isManualCitySelected = false;
  bool _isMarkerAnimating = false;

  bool _isProgrammaticMove = false;
  bool _isUserMovingMap = false;
  bool _isMapReady = false;

  static const int _pinNormalSize = 640;
  static const int _pinSelectedSize = 780;
  static const int _pinPopSize = 900;

  static const double _pinNormalIconSize = 0.52;
  static const double _pinSelectedIconSize = 0.65;

  static const double _normalSortKey = 1;
  static const double _selectedSortKey = 9999;

  late AnimationController _cardController;
  late Animation<Offset> _cardSlide;

  /// Serializes marker create/update so two overlapping syncs cannot each pass
  /// `!_restaurantPins.containsKey(id)` before `create` completes — that orphan
  /// leaves a duplicate pin on the map (e.g. list tap while another sync runs).
  Future<void> _pinSyncTail = Future<void>.value();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

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
    _debounce?.cancel();
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

            if (mounted && !_isManualCitySelected && cities.isNotEmpty) {
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
                _cityName = cityName;
                _selectedCityId = matchedCity.id;
              });

              // Re-run restaurant load now that we have the proper city ID
              await _loadCityRestaurants();
            }
          } catch (e) {
            debugPrint("Error detecting city: $e");
          }
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
      final double? queryLat = _isManualCitySelected ? _center?.coordinates.lat.toDouble() : _userLocation?.coordinates.lat.toDouble();
      final double? queryLon = _isManualCitySelected ? _center?.coordinates.lng.toDouble() : _userLocation?.coordinates.lng.toDouble();

      final list = await _restaurantService.getRestaurants(
        cityId: _selectedCityId,
        latitude: queryLat,
        longitude: queryLon,
        search: _searchController.text.trim(),
        cuisines: _selectedCuisineId,
        day: _selectedDay,
        time: _selectedTime,
      );

      if (!mounted) return;

      setState(() {
        _cityRestaurants = list;
        _filteredRestaurants = list;

        _isLoading = false;
        _isCityListLoading = false;
      });

      await _ensureMarkerBytes();
      await _syncPinsWithList();
      
      final hasActiveFilter = _searchController.text.trim().isNotEmpty || 
                              _selectedCuisineId != null || 
                              _selectedDay != null || 
                              _selectedTime != null;
                              
      if (hasActiveFilter && list.length == 1) {
        final r = list.first;
        setState(() {
          _selectedRestaurant = r;
          _selectedRestaurantId = r.id;
        });
        _cardController.forward(from: 0);
        await _refreshPinsStateOnly();
        await _bounceSelectedMarker(r.id);
        await _moveToRestaurant(r);
      } else {
        await _moveCameraToCenter();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cityRestaurants = [];
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

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadCityRestaurants();
    });
  }


  void _openRestaurant(Restaurant restaurant) {
    // Prefer the user's actual GPS position for distance calculations in the
    // details page, fall back to the current map centre if GPS isn't available.
    final userLat = _userLocation?.coordinates.lat.toDouble()
        ?? _center?.coordinates.lat.toDouble();
    final userLon = _userLocation?.coordinates.lng.toDouble()
        ?? _center?.coordinates.lng.toDouble();

    final slug = restaurant.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RestaurantDetailsPage(slug: slug, latitude: userLat, longitude: userLon),
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
        tags.add("${restaurant.discount.percentage?.toInt() ?? 0}% Off");
        break;

      case 'fixed':
        if (restaurant.discount.fixedAmount != null) {
          tags.add(
            "£${restaurant.discount.fixedAmount!.toStringAsFixed(0)} Off",
          );
        } else {
          tags.add(restaurant.discount.displayText);
        }
        break;

      case 'combo':
        tags.add(restaurant.discount.displayText);
        break;
    }

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
    required String dealText,
    required String restaurantName,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final double s = size.toDouble();
    // Increase canvas width significantly to stop text from truncating left or right
    final double canvasWidth = s * 2.8; 
    final double canvasHeight = s * 1.5; 

    // Scale down pin to offer plenty of breathing room for bubbles above and below
    final double pinScale = 0.50; 
    final double scaledS = s * pinScale;
    
    // Start drawing downward to avoid cropping the top bubble
    final double yOffset = canvasHeight * 0.20;

    // The literal pointy bit of the marker
    final Offset rawTip = Offset(canvasWidth / 2, yOffset + scaledS * 0.92);
    
    // Center the TIP identically so Mapbox IconAnchor.CENTER applies accurately natively.
    final double dy = (canvasHeight / 2) - rawTip.dy;
    canvas.save();
    canvas.translate(0, dy);

    final double topRadius = scaledS * 0.28;
    final Offset topCenter = Offset(canvasWidth / 2, rawTip.dy - topRadius * 2.20);

    // 1. Drop shadow 
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(topCenter.dx, topCenter.dy + scaledS * 0.55),
        width: scaledS * 0.45,
        height: scaledS * 0.15,
      ),
      shadowPaint,
    );

    // 2. Draw Pin Body Geometry
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

    // 3. Fill Pin Body
    final fillPaint = Paint()..color = Colors.white;
    canvas.drawPath(path, fillPaint);

    // Subtle stroke border
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: selected ? 0.2 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scaledS * 0.025;
    canvas.drawPath(path, borderPaint);

    // Draw the white inner circle
    final innerCirclePaint = Paint()..color = const Color(0xFFF9FAFB); 
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

    // 7. Draw Deal Bubble (Top)
    if (dealText.isNotEmpty) {
      final TextSpan span = TextSpan(
        text: dealText,
        style: AppTypography.title.copyWith(
          fontSize: selected ? scaledS * 0.17 : scaledS * 0.15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      final double padH = scaledS * 0.08;
      final double padV = scaledS * 0.04;
      final double pillWidth = tp.width + padH * 2;
      final double pillHeight = tp.height + padV * 2;

      final Rect pillRect = Rect.fromCenter(
        center: Offset(topCenter.dx, topCenter.dy - topRadius - pillHeight / 2 - scaledS * 0.04),
        width: pillWidth,
        height: pillHeight,
      );

      final Gradient pillGradient = const LinearGradient(
        colors: [Color(0xFFD946EF), Color(0xFFA855F7)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
      final pillPaint = Paint()..shader = pillGradient.createShader(pillRect);

      final pillShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect.translate(0, 4), Radius.circular(pillHeight / 2)),
        pillShadowPaint,
      );

      final pointerPath = Path();
      pointerPath.moveTo(topCenter.dx - scaledS * 0.05, pillRect.bottom - 1);
      pointerPath.lineTo(topCenter.dx + scaledS * 0.05, pillRect.bottom - 1);
      pointerPath.lineTo(topCenter.dx, pillRect.bottom + scaledS * 0.08);
      pointerPath.close();
      canvas.drawPath(pointerPath, pillPaint);
      
      canvas.drawRRect(RRect.fromRectAndRadius(pillRect, Radius.circular(pillHeight / 2)), pillPaint);
      tp.paint(canvas, Offset(pillRect.left + padH, pillRect.top + padV));
    }

    // 8. Draw Restaurant Name Bubble (Bottom)
    if (restaurantName.isNotEmpty) {
      final TextSpan span = TextSpan(
        text: restaurantName,
        style: AppTypography.title.copyWith(
          fontSize: selected ? scaledS * 0.15 : scaledS * 0.13,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      final double padH = scaledS * 0.08;
      final double padV = scaledS * 0.04;
      final double pillWidth = tp.width + padH * 2;
      final double pillHeight = tp.height + padV * 2;

      final Rect pillRect = Rect.fromCenter(
        center: Offset(topCenter.dx, tip.dy + pillHeight / 2 + scaledS * 0.04),
        width: pillWidth,
        height: pillHeight,
      );

      final pillPaint = Paint()..color = Colors.white;

      final pillShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect.translate(0, 4), Radius.circular(pillHeight / 2)),
        pillShadowPaint,
      );

      final pillOutlinePaint = Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = scaledS * 0.01;

      final pointerPath = Path();
      pointerPath.moveTo(topCenter.dx - scaledS * 0.05, pillRect.top + 1);
      pointerPath.lineTo(topCenter.dx + scaledS * 0.05, pillRect.top + 1);
      pointerPath.lineTo(topCenter.dx, pillRect.top - scaledS * 0.08);
      pointerPath.close();
      canvas.drawPath(pointerPath, pillPaint);
      canvas.drawPath(pointerPath, pillOutlinePaint); // draw outline for pointer

      canvas.drawRRect(RRect.fromRectAndRadius(pillRect, Radius.circular(pillHeight / 2)), pillPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(pillRect, Radius.circular(pillHeight / 2)), pillOutlinePaint);

      // Redraw pointer fill to hide outline line behind pointer
      final pointerFillPaint = Paint()..color = Colors.white;
      canvas.drawPath(pointerPath, pointerFillPaint);
      
      tp.paint(canvas, Offset(pillRect.left + padH, pillRect.top + padV));
    }

    canvas.restore();
    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  Future<Uint8List> _getMarkerBytes(String dealText, String restaurantName, bool selected, bool popping) async {
    final cacheKey = '${dealText}_${restaurantName}_${selected}_$popping';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }
    
    final int size = popping ? _pinPopSize : (selected ? _pinSelectedSize : _pinNormalSize);
    
    final bytes = await _createDropPinMarkerBytes(
      size: size,
      selected: selected,
      dealText: dealText,
      restaurantName: restaurantName,
    );
    
    _markerCache[cacheKey] = bytes;
    return bytes;
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

  Future<void> _syncPinsWithList() {
    return _pinSyncTail = _pinSyncTail.then((_) => _syncPinsWithListBody());
  }

  Future<void> _syncPinsWithListBody() async {
    if (_pointManager == null) return;

    try {
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
          try {
            _userDotAnnotation!.geometry = _userLocation!;
            await _pointManager!.update(_userDotAnnotation!);
          } catch (e) {
            // If the annotation was removed or lost on the native side
            _userDotAnnotation = null;
          }
        }
      }

      final existingIds = _restaurantPins.keys.toSet();
      final requiredIds = _filteredRestaurants.map((e) => e.id).toSet();

      for (final id in existingIds.difference(requiredIds)) {
        final ann = _restaurantPins[id];
        if (ann != null) {
          try {
            await _pointManager!.delete(ann);
          } catch (e) {
            // Ignore if already deleted
          }
        }
        _restaurantPins.remove(id);
        _annotationIdToRestaurantId.removeWhere((key, value) => value == id);
      }

      for (final r in _filteredRestaurants) {
        if (_restaurantPins.containsKey(r.id)) continue;

        final bool isSelected = r.id == _selectedRestaurantId;
        final dealText = r.activeDeals.isNotEmpty && r.activeDeals.first.title != null && r.activeDeals.first.title!.isNotEmpty
            ? r.activeDeals.first.title!
            : r.discount.displayText;
        final imageBytes = await _getMarkerBytes(dealText, r.name, isSelected, false);

        final ann = await _pointManager!.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(r.longitude, r.latitude)),
            image: imageBytes,
            iconSize: isSelected ? _pinSelectedIconSize : _pinNormalIconSize,
            iconAnchor: IconAnchor.CENTER,
            iconOffset: [0.0, 0.0],
            symbolSortKey: isSelected ? _selectedSortKey : _normalSortKey,
          ),
        );

        _restaurantPins[r.id] = ann;
        _annotationIdToRestaurantId[ann.id] = r.id;
      }

      await _refreshPinsStateOnly();
    } catch (e, st) {
      debugPrint('NearbyPage: _syncPinsWithListBody failed: $e\n$st');
    }
  }

  Future<void> _refreshPinsStateOnly() async {
    if (_pointManager == null) return;

    for (final r in _filteredRestaurants) {
      final ann = _restaurantPins[r.id];
      if (ann == null) continue;

      final bool isSelected = r.id == _selectedRestaurantId;
      final dealText = r.activeDeals.isNotEmpty && r.activeDeals.first.title != null && r.activeDeals.first.title!.isNotEmpty
          ? r.activeDeals.first.title!
          : r.discount.displayText;

      ann.image = await _getMarkerBytes(dealText, r.name, isSelected, false);
      ann.iconSize = isSelected ? _pinSelectedIconSize : _pinNormalIconSize;
      ann.iconAnchor = IconAnchor.CENTER;
      ann.iconOffset = [0.0, 0.0];
      ann.symbolSortKey = isSelected ? _selectedSortKey : _normalSortKey;

      try {
        await _pointManager!.update(ann);
      } catch (e) {
        _restaurantPins.remove(r.id);
        _annotationIdToRestaurantId.remove(ann.id);
      }
    }
  }

  Future<void> _bounceSelectedMarker(String id) async {
    if (_pointManager == null) return;
    if (_isMarkerAnimating) return;

    final ann = _restaurantPins[id];
    if (ann == null) return;

    final r = _filteredRestaurants.firstWhere((res) => res.id == id, orElse: () => _filteredRestaurants.first);
    final dealText = r.activeDeals.isNotEmpty && r.activeDeals.first.title != null && r.activeDeals.first.title!.isNotEmpty
        ? r.activeDeals.first.title!
        : r.discount.displayText;

    _isMarkerAnimating = true;

    try {
      ann.image = await _getMarkerBytes(dealText, r.name, true, false);
      ann.symbolSortKey = _selectedSortKey;
      
      const int steps = 24;
      const int durationMs = 600;
      final int stepDurationMs = durationMs ~/ steps;

      for (int i = 0; i <= steps; i++) {
        final double t = i / steps;
        final double curve = Curves.elasticOut.transform(t);
        
        final double scale = _pinNormalIconSize + (_pinSelectedIconSize - _pinNormalIconSize) * curve;
        ann.iconSize = scale;
        
        await _pointManager!.update(ann);
        await Future.delayed(Duration(milliseconds: stepDurationMs));
      }
      
      ann.iconSize = _pinSelectedIconSize;
      await _pointManager!.update(ann);
    } catch (e) {
      _restaurantPins.remove(id);
      _annotationIdToRestaurantId.remove(ann.id);
    }

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
            return Container(
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: GenericBottomSheet(
                title: "Restaurants in $_cityName",
                onClose: () => Navigator.pop(context),
                backgroundColor: Colors.transparent,
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

                                  // _syncPinsWithList already ends with _refreshPinsStateOnly
                                  await _syncPinsWithList();
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
                                                fontWeight: FontWeight.w700,
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
    return AppScaffold(
        body: _center == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2F80ED)),
            )
          : Stack(
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    AppColors.primaryPurple.withValues(alpha: 0.12),
                    BlendMode.srcATop,
                  ),
                  child: MapWidget(
                    key: const ValueKey("mapWidget"),
                    cameraOptions: CameraOptions(center: _center!, zoom: _zoom),
                    styleUri: MapboxStyles.LIGHT,
                  onMapCreated: (mapboxMap) async {
                    _mapboxMap = mapboxMap;

                    if (mounted) {
                      setState(() => _isMapReady = true);
                    }

                    if (_pointManager != null) {
                      await _mapboxMap!.annotations.removeAnnotationManager(_pointManager!);
                    }
                    _pointManager = await _mapboxMap!.annotations
                        .createPointAnnotationManager();

                    // RESET TRACKERS
                    _userDotAnnotation = null;
                    _restaurantPins.clear();
                    _annotationIdToRestaurantId.clear();

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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _isSearching ? _searchTopBar() : _normalTopBar(),
                  ),
                ),

                if (_selectedRestaurant != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom:
                        50, // Adjusted to prevent touching bottom navigation bar
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
                        50, // Adjusted to prevent touching bottom navigation bar
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
    final cityFontSize = 24.0;

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
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, size: 28),
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
        const SizedBox(width: 8),
        InkWell(
          onTap: _openFilters,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              Icons.filter_list,
              size: 28,
              color: _selectedCuisineId != null
                  ? AppColors.primary
                  : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  void _openFilters() {
    _showFilterModal();
  }

  void _showFilterModal() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final currentDayString = _selectedDay != null ? days[_selectedDay!] : null;

    final reverseTimes = {
      '09:00:00': 'Morning',
      '12:00:00': 'Lunch',
      '15:00:00': 'Afternoon',
      '18:00:00': 'Evening',
      '20:00:00': 'Night',
    };
    final currentTimeString = _selectedTime != null ? reverseTimes[_selectedTime] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => FilterModal(
        initialDay: currentDayString,
        initialTime: currentTimeString,
        initialCuisineId: _selectedCuisineId,
        onApply: (filters) {
          setState(() {
            _selectedCuisineId = filters['cuisine_id'];

            _selectedDay = filters['day'] != null ? days.indexOf(filters['day']) : null;
            
            final times = {
              'Morning': '09:00:00',
              'Lunch': '12:00:00',
              'Afternoon': '15:00:00',
              'Evening': '18:00:00',
              'Night': '20:00:00',
            };
            _selectedTime = filters['time'] != null ? times[filters['time']] : null;
          });
          _loadCityRestaurants();
        },
      ),
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
                    textAlignVertical: TextAlignVertical.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
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
            onTap: _showFilterModal,
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
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
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
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.button.copyWith(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _centerMapOnLocation,
          borderRadius: BorderRadius.circular(60),
          child: const Icon(Icons.navigation, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _restaurantPreviewCard(Restaurant restaurant) {
    // Compute pinpoint-accurate miles using user GPS; fall back gracefully
    final userLat = _userLocation?.coordinates.lat.toDouble();
    final userLon = _userLocation?.coordinates.lng.toDouble();
    final miles = DistanceUtils.bestMiles(
      userLat: userLat,
      userLon: userLon,
      restaurantLat: restaurant.latitude,
      restaurantLon: restaurant.longitude,
      distanceMilesFromApi: restaurant.distanceMiles,
      distanceKmFromApi: restaurant.distance,
    );
    final tags = _getOfferTags(restaurant);

    return GestureDetector(
      onTap: () => _openRestaurant(restaurant),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
          borderRadius: AppRadius.xLarge,
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: restaurant.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
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
                        )
                      : Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.restaurant),
                        ),
                ),
                if (restaurant.rating > 0)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
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
                          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 12),
                          const SizedBox(width: 2),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: AppTypography.title.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: OccupancyTag(
                          occupancy: restaurant.occupancy,
                          isSmall: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Description below name
                  if (restaurant.description.trim().isNotEmpty) ...[
                    Text(
                      restaurant.description.trim(),
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.black54,
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],

                  // Cuisine and distance
                  Row(
                    children: [
                      if (restaurant.cuisine.isNotEmpty) ...[
                        Expanded(
                          child: Text(
                            restaurant.cuisine,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.black38,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text("  •  ", style: TextStyle(color: Colors.black12, fontSize: 10)),
                      ],
                      const Icon(Icons.location_on, color: Color(0xFF8B5CF6), size: 10),
                      const SizedBox(width: 2),
                      Text(
                        "${miles?.toStringAsFixed(1) ?? '—'} mi",
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Wrap with tags (discounts)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 9,
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
