import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:discount_buddy/config/environment.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'main_navigation.dart';
import '../models/restaurant.dart';
import '../models/restaurant_detail.dart';
import '../models/review.dart';
import '../models/menu_item.dart';
import '../services/restaurant_service.dart';
import '../services/location_service.dart';
import 'package:discount_buddy/design/app_colors.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';
import 'package:discount_buddy/design/app_radius.dart';
import 'package:discount_buddy/design/app_shadows.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/generic_bottom_sheet.dart';
import 'deals/redeem_offer_modal.dart';
import 'bookings/booking_selection_modal.dart';
import '../models/mystery_visit.dart';
import '../services/mystery_guest_service.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import 'mystery_guest/mystery_audit_modal.dart';
import '../widgets/occupancy_tag.dart';
import '../widgets/login_required_sheet.dart';
import '../utils/distance_utils.dart';

/// Restaurant details page - NeoTaste style
class RestaurantDetailsPage extends StatefulWidget {
  final String slug;
  final double? latitude;
  final double? longitude;

  const RestaurantDetailsPage({
    super.key,
    required this.slug,
    this.latitude,
    this.longitude,
  });

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  final MysteryGuestService _mysteryGuestService = MysteryGuestService();
  final AuthProvider _authProvider = AuthProvider();

  RestaurantDetail? _restaurantDetail;
  MysteryVisit? _activeVisit;
  List<MysteryVisit> _allVisits = [];
  bool _isMysteryGuest = false;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _errorMessage;

  // Resolved user coordinates (from widget args or on-demand GPS)
  double? _resolvedUserLat;
  double? _resolvedUserLon;

  ui.Image? _appLogoImage;
  Uint8List? _pinNormalBytes;

  // Carousel
  final PageController _imagePageController = PageController();
  Timer? _carouselTimer;
  int _currentImageIndex = 0;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _authProvider.addListener(_onAuthStateChanged);

    // Check multiple sources for mystery_guest role to be safe
    final roleFromProvider = _authProvider.userRole;
    final roleFromProfile = _authProvider.user?.profile?.role;
    final isMysteryFromUser = _authProvider.user?.isMysteryGuest ?? false;
    _isMysteryGuest =
        _authProvider.isMysteryGuest ||
        roleFromProfile == 'mystery_guest' ||
        isMysteryFromUser;
    debugPrint('DEBUG RestaurantDetails.initState:');
    debugPrint('  roleFromProvider="$roleFromProvider"');
    debugPrint('  roleFromProfile="$roleFromProfile"');
    debugPrint('  isMysteryFromUser=$isMysteryFromUser');
    debugPrint('  FINAL _isMysteryGuest=$_isMysteryGuest');
    _loadRestaurant();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    _carouselTimer?.cancel();
    _imagePageController.dispose();
    // Mapbox map doesn't need manual dispose for the controller here
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    // Do not start if user is interacting
    if (_isUserInteracting) return;

    final images = _restaurantDetail?.restaurant.restaurantImages
        .where((img) => img.imageType == 'gallery')
        .toList();

    // Safety check - need at least 2 images to carousel
    if (images == null || images.length <= 1) return;

    _carouselTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      if (_isUserInteracting) return; // Guard during periodic fire

      if (_imagePageController.hasClients) {
        _currentImageIndex = (_currentImageIndex + 1) % images.length;
        _imagePageController.animateToPage(
          _currentImageIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    if (!_authProvider.isAuthenticated && !_authProvider.isGuestMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.offAllNamed(AppRoutes.login);
        }
      });
    }
  }

  Future<Uint8List> _createDropPinMarkerBytes({required int size}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final double s = size.toDouble();
    final Offset topCenter = Offset(s / 2, s * 0.38);

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
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

    // Pin Body
    final fillPaint = Paint()..color = Colors.white;
    canvas.drawPath(path, fillPaint);

    // Subtle stroke border
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025;
    canvas.drawPath(path, borderPaint);

    // Draw the white inner circle
    final innerCirclePaint = Paint()..color = AppColors.background;
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

    _pinNormalBytes ??= await _createDropPinMarkerBytes(size: 140);
  }

  Future<void> _loadRestaurant() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Resolve user coordinates: use passed‑in values first, then try GPS
      double? lat = widget.latitude;
      double? lon = widget.longitude;
      if (lat == null || lon == null) {
        try {
          final pos = await _locationService.getCurrentLocation();
          lat = pos.latitude;
          lon = pos.longitude;
        } catch (_) {
          // Location unavailable — distance will show as '—'
        }
      }
      _resolvedUserLat = lat;
      _resolvedUserLon = lon;

      final restaurantDetail = await _restaurantService
          .getRestaurantDetailBySlug(
            widget.slug,
            latitude: lat,
            longitude: lon,
          );
      setState(() {
        _restaurantDetail = restaurantDetail;
        _isFavorite = restaurantDetail.restaurant.isFavourite;
        _isLoading = false;
      });

      _startCarouselTimer();

      // Check for mystery visit if user is a mystery guest
      if (_isMysteryGuest) {
        debugPrint('DEBUG: User is mystery guest, checking visits...');
        _checkMysteryVisit();
      } else {
        debugPrint(
          'DEBUG: User is NOT mystery guest (role: ${_authProvider.userRole})',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkMysteryVisit() async {
    if (_restaurantDetail == null) return;
    try {
      final restaurantId = int.tryParse(_restaurantDetail!.restaurant.id) ?? 0;
      debugPrint(
        'DEBUG: Fetching mystery visits for restaurant ID: $restaurantId',
      );
      final visits = await _mysteryGuestService.getAssignedVisits(
        restaurantId: restaurantId,
      );

      debugPrint('DEBUG: Got ${visits.length} mystery visits');
      for (final v in visits) {
        debugPrint(
          'DEBUG: Visit #${v.id} status="${v.status}" restaurantId=${v.restaurantId}',
        );
      }

      if (mounted) {
        setState(() {
          _allVisits = visits;
          // Find active visit (assigned or in_progress)
          final activeVisits = visits
              .where((v) => v.status == 'assigned' || v.status == 'in_progress')
              .toList();
          if (activeVisits.isNotEmpty) {
            _activeVisit = activeVisits.first;
            debugPrint(
              'DEBUG: Active visit found: #${_activeVisit!.id} status="${_activeVisit!.status}"',
            );
          } else {
            debugPrint(
              'DEBUG: No active visit found. Statuses: ${visits.map((v) => v.status).toList()}',
            );
          }
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error checking mystery visit: $e');
    }
  }

  void _showMysteryAuditModal() {
    if (_activeVisit == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MysteryAuditModal(
        visit: _activeVisit!,
        onUpdate: (updatedVisit) {
          setState(() {
            if (updatedVisit.status == 'submitted' ||
                updatedVisit.status == 'cancelled') {
              _activeVisit = null;
            } else {
              _activeVisit = updatedVisit;
            }
          });
        },
      ),
    );
  }

  String _formatTimeWithoutSeconds(String timeStr) {
    timeStr = timeStr.trim();
    // Check if there is an AM/PM designator
    final amPmMatch = RegExp(r'\s*(AM|PM|am|pm)\s*$').firstMatch(timeStr);
    String suffix = '';
    String timePart = timeStr;
    if (amPmMatch != null) {
      suffix = ' ${amPmMatch.group(1)}';
      timePart = timeStr.substring(0, amPmMatch.start).trim();
    }

    final parts = timePart.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}$suffix';
    }
    return timeStr;
  }

  // Get opening hours (using restaurant opening hours or default)
  String _getOpeningHours(Restaurant restaurant) {
    if (restaurant.openingSlots.isNotEmpty) {
      final now = DateTime.now();
      final currentDay = DateFormat('EEEE').format(now);
      final currentTime = TimeOfDay.now();

      // Find today's slot
      final todaySlot = restaurant.openingSlots.firstWhere(
        (slot) => slot.dayName.toLowerCase() == currentDay.toLowerCase(),
        orElse: () => null as dynamic,
      );

      final slot = todaySlot;
      if (slot.isClosed) {
        return 'Closed';
      }

      try {
        final closingParts = slot.closingTime.split(':');
        final closingHour = int.parse(closingParts[0]);
        final closingMinute = closingParts.length > 1
            ? int.parse(closingParts[1])
            : 0;
        final closingTime = TimeOfDay(hour: closingHour, minute: closingMinute);

        final isClosed =
            currentTime.hour > closingTime.hour ||
            (currentTime.hour == closingTime.hour &&
                currentTime.minute >= closingMinute);

        if (isClosed) {
          return 'Closed';
        }

        return 'Open until ${_formatTimeWithoutSeconds(slot.closingTime)}';
      } catch (_) {
        // Fallback if parsing fails
      }
    }

    // Check if opening_hours is a Map (from API) with day names as keys
    try {
      final now = DateTime.now();
      final currentDay = DateFormat('EEEE').format(now).toLowerCase();
      final currentTime = TimeOfDay.now();

      // The opening_hours from API is typically a Map<String, String> with day names
      if (restaurant.openingHours is Map) {
        final hoursMap = restaurant.openingHours as Map;
        if (hoursMap.isNotEmpty) {
          final todayHours = hoursMap[currentDay];

          if (todayHours != null &&
              todayHours is String &&
              todayHours.contains('-')) {
            final parts = todayHours.split('-');
            if (parts.length > 1) {
              final closingTime = parts[1].trim();
              final closingParts = closingTime.split(':');
              final closingHour = int.parse(closingParts[0]);
              final closingMinute = closingParts.length > 1
                  ? int.parse(closingParts[1])
                  : 0;
              final closing = TimeOfDay(
                hour: closingHour,
                minute: closingMinute,
              );

              final isClosed =
                  currentTime.hour > closing.hour ||
                  (currentTime.hour == closing.hour &&
                      currentTime.minute >= closingMinute);

              if (isClosed) {
                return 'Closed';
              }

              return 'Open until ${_formatTimeWithoutSeconds(closingTime)}';
            }
          }
        }
      }
    } catch (_) {
      // Continue to fallback
    }

    // Legacy fallback for List format
    if ((restaurant.openingHours as List).isNotEmpty) {
      final firstHour = (restaurant.openingHours as List)[0];
      if (firstHour is String && firstHour.contains('-')) {
        final parts = firstHour.split('-');
        if (parts.length > 1) {
          return 'Open until ${_formatTimeWithoutSeconds(parts[1].trim())}';
        }
      }
      return firstHour.toString();
    }

    return '';
  }

  // Get price range widget

  // Toggle favorite status
  Future<void> _toggleFavorite() async {
    if (_authProvider.isGuestMode) {
      LoginRequiredSheet.show(context);
      return;
    }
    if (_restaurantDetail == null) return;

    final slug =
        _restaurantDetail!.restaurant.slug ?? _restaurantDetail!.restaurant.id;
    final currentStatus = _isFavorite;

    setState(() {
      _isFavorite = !currentStatus;
    });

    try {
      final newStatus = await _restaurantService.toggleFavourite(
        slug,
        currentStatus,
      );
      if (mounted) {
        setState(() {
          _isFavorite = newStatus;
        });
      }
    } catch (e) {
      // Revert if failed
      if (mounted) {
        setState(() {
          _isFavorite = currentStatus;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // Show add review dialog
  void _showAddReviewDialog() {
    if (_authProvider.isGuestMode) {
      LoginRequiredSheet.show(context);
      return;
    }
    if (_restaurantDetail == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => _AddReviewDialog(
        restaurantId: int.tryParse(_restaurantDetail!.restaurant.id) ?? 0,
        onSubmit: (rating, comment) async {
          try {
            await _restaurantService.addReview(
              restaurantId: int.tryParse(_restaurantDetail!.restaurant.id) ?? 0,
              rating: rating,
              comment: comment,
            );
            // Reload restaurant to show new review
            if (mounted) {
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext); // Close dialog first
              _loadRestaurant();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review added successfully!')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.toString())));
            }
            // Rethrow to let dialog know
            rethrow;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _restaurantDetail == null) {
      return AppScaffold(
        appBar: AppBar(
          title: const Text('Restaurant Details'),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Failed to load restaurant',
                style: AppTypography.body.copyWith(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppGradientButton(
                onPressed: _loadRestaurant,
                width: 120,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final restaurant = _restaurantDetail!.restaurant;
    final reviews = _restaurantDetail!.reviews;
    final menuCategories = _restaurantDetail!.menuCategories;
    // Distance calculation is handled, but dist variable itself is not used currently
    // final dist = restaurant.distanceMiles ?? _kmToMiles(restaurant.distance);

    return AppScaffold(
      body: CustomScrollView(
        cacheExtent:
            500, // Limit off-screen rendering to reduce memory pressure
        slivers: [
          // Header with full-width image and gradient
          SliverAppBar(
            expandedHeight: 300,
            pinned: false,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (() {
                      final images = restaurant.restaurantImages
                          .where((img) => img.imageType == 'gallery')
                          .toList();

                      if (images.isEmpty && restaurant.imageUrl.isEmpty) {
                        return Container(
                          color: AppColors.textDisabled,
                          child: const Icon(Icons.restaurant, size: 64),
                        );
                      }

                      // If we have restaurantImages, use PageView. Otherwise just the fallback imageUrl.
                      if (images.isNotEmpty) {
                        return NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollStartNotification) {
                              _isUserInteracting = true;
                              _carouselTimer?.cancel();
                            } else if (notification is ScrollEndNotification) {
                              _isUserInteracting = false;
                              _startCarouselTimer();
                            }
                            return false;
                          },
                          child: PageView.builder(
                            controller: _imagePageController,
                            itemCount: images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: images[index].image.urlFor(fullScreen: true) ?? '',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.textDisabled,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.textDisabled,
                                  child: const Icon(Icons.restaurant, size: 64),
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        // Fallback to primary imageUrl if available
                        return CachedNetworkImage(
                          imageUrl: restaurant.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.textDisabled,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.textDisabled,
                            child: const Icon(Icons.restaurant, size: 64),
                          ),
                        );
                      }
                    })(),

                    // Carousel Indicators (Dots)
                    (() {
                      final imagesCount = restaurant.restaurantImages
                          .where((img) => img.imageType == 'gallery')
                          .length;
                      if (imagesCount <= 1) return const SizedBox.shrink();

                      return Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(imagesCount, (index) {
                            final isActive = _currentImageIndex == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      );
                    })(),

                    // White gradient fade at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppColors.surface],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Restaurant Info Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                restaurant.name,
                                style: AppTypography.title.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OccupancyTag(occupancy: restaurant.occupancy),
                      if (restaurant.leaderboardScore > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.leaderboard,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.leaderboardScore.toStringAsFixed(1),
                                style: AppTypography.title.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (restaurant.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      restaurant.description,
                      style: AppTypography.body.copyWith(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Details Rows
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Cuisine & Categories
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (restaurant.cuisine.isNotEmpty)
                            Text(
                              restaurant.cuisine,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          if (restaurant.cuisine.isNotEmpty &&
                              restaurant.categories.isNotEmpty)
                            const Icon(
                              Icons.circle,
                              size: 3,
                              color: AppColors.textDisabled,
                            ),
                          if (restaurant.categories.isNotEmpty)
                            Text(
                              restaurant.categories
                                  .map((e) => e.name)
                                  .join(' • '),
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Row 2: Address, Price, and Timing
                      Row(
                        children: [
                          // Address & Distance
                          Flexible(
                            child: Text(
                              () {
                                final miles = DistanceUtils.bestMiles(
                                  userLat: _resolvedUserLat,
                                  userLon: _resolvedUserLon,
                                  restaurantLat: restaurant.latitude,
                                  restaurantLon: restaurant.longitude,
                                  distanceMilesFromApi:
                                      restaurant.distanceMiles,
                                  distanceKmFromApi: restaurant.distance,
                                );
                                final milesStr = miles != null
                                    ? '${miles.toStringAsFixed(1)} mi'
                                    : '-- mi';
                                return '${restaurant.address.split(',').first} • $milesStr';
                              }(),
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.circle,
                            size: 3,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(width: 6),
                          // Specific Price logic inline for compactness
                          RichText(
                            text: TextSpan(
                              children: List.generate(4, (i) {
                                final isActive =
                                    i < (restaurant.priceRange ?? 2);
                                return TextSpan(
                                  text: '£',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 13,
                                    color: isActive
                                        ? AppColors.textPrimary
                                        : AppColors.textDisabled.withValues(
                                            alpha: 0.4,
                                          ),
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.circle,
                            size: 3,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(width: 6),
                          // Opening Hours
                          Text(
                            _getOpeningHours(restaurant),
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      // Menu Button
                      Expanded(
                        child: AppGradientButton(
                          onPressed: () {
                            _showMenuPopup(context, restaurant, menuCategories);
                          },
                          height: 48,
                          borderRadius: AppRadius.xLarge,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Menu',
                                style: AppTypography.title.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Favorite Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: AppShadows.card,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _toggleFavorite,
                            borderRadius: BorderRadius.circular(14),
                            child: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? Colors.red
                                  : AppColors.textPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Share Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: AppShadows.card,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final dealText = restaurant.discount.displayText;
                              final dealDesc = restaurant.discount.description;
                              const appStoreLink =
                                  'https://apps.apple.com/in/app/discount-buddy-deals/id6760362068';
                              const playStoreLink =
                                  'https://play.google.com/store/apps/details?id=com.discountbuddy.app';

                              final message =
                                  '🔥 Check out this amazing deal at ${restaurant.name}!\n\n'
                                  '✨ $dealText\n'
                                  '📝 $dealDesc\n\n'
                                  '📍 ${restaurant.address}\n\n'
                                  'Download the App:\n'
                                  '🍎 iOS: $appStoreLink\n'
                                  '🤖 Android: $playStoreLink';

                              // ignore: deprecated_member_use
                              Share.share(message);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: const Icon(
                              Icons.share,
                              color: AppColors.textPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Mystery Audit Section - only show if assigned for this restaurant
          if (_isMysteryGuest && _allVisits.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade50],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _activeVisit != null
                                ? 'Mystery Audit'
                                : 'Mystery Guest',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                        if (_activeVisit != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _activeVisit!.status == 'in_progress'
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _activeVisit!.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _activeVisit!.status == 'in_progress'
                                    ? AppColors.success
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Show different content based on visit state
                    if (_activeVisit != null) ...[
                      Text(
                        'Complete your anonymous audit to help improve quality and earn rewards.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppGradientButton(
                        onPressed: _showMysteryAuditModal,
                        height: 48,
                        borderRadius: BorderRadius.circular(10),
                        child: Text(
                          _activeVisit!.status == 'assigned'
                              ? 'Start Audit'
                              : 'Continue Audit',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ] else if (_allVisits.any(
                      (v) => v.status == 'submitted',
                    )) ...[
                      // Show submitted visit summary
                      ...(_allVisits
                          .where((v) => v.status == 'submitted')
                          .take(1)
                          .map(
                            (v) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.success.withValues(
                                        alpha: 0.8,
                                      ),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Audit Submitted',
                                      style: AppTypography.title.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (v.overallScore != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Overall Score: ',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 14,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      Text(
                                        '${v.overallScore!.toStringAsFixed(1)}/100',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          )),
                    ] else ...[
                      Text(
                        'No audit is currently assigned for this restaurant. You can view and manage your visits from the dashboard.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Loyalty Card Section
          if (restaurant.loyaltyCardEnabled && restaurant.loyaltyProgram != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _LoyaltyCardSection(
                  loyaltyProgram: restaurant.loyaltyProgram!,
                  isGuestMode: _authProvider.isGuestMode,
                ),
              ),
            ),

          // Offer Card Section
          if (restaurant.activeDeals.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Active Offers 📢',
                      style: AppTypography.body.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (restaurant.activeDeals.length > 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: restaurant.activeDeals.map((deal) {
                          return Container(
                            width: 300,
                            margin: const EdgeInsets.only(right: 12),
                            child: _OfferCard(discount: deal),
                          );
                        }).toList(),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _OfferCard(discount: restaurant.activeDeals.first),
                    ),
                ],
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 17)),

          // Facilities Section
          if (restaurant.facilities.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Facilities 🛠️',
                      style: AppTypography.body.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: restaurant.facilities.map((fac) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              (() {
                                String icon = fac.icon;
                                if (icon.isEmpty) {
                                  // Fallback icons based on name
                                  final name = fac.name.toLowerCase();
                                  if (name.contains('dine-in')) {
                                    icon = '🪑';
                                  } else if (name.contains('takeaway')) {
                                    icon = '🥡';
                                  } else if (name.contains('delivery')) {
                                    icon = '🛵';
                                  } else if (name.contains('outdoor')) {
                                    icon = '⛱️';
                                  } else if (name.contains('wifi')) {
                                    icon = '📶';
                                  } else if (name.contains('parking')) {
                                    icon = '🅿️';
                                  } else if (name.contains('toilet') ||
                                      name.contains('washroom')) {
                                    icon = '🚻';
                                  } else if (name.contains('card')) {
                                    icon = '💳';
                                  } else if (name.contains('alcohol')) {
                                    icon = '🍺';
                                  } else if (name.contains('music')) {
                                    icon = '🎵';
                                  } else if (name.contains('child') ||
                                      name.contains('kid')) {
                                    icon = '👶';
                                  } else if (name.contains('accessible') ||
                                      name.contains('wheelchair')) {
                                    icon = '♿';
                                  }
                                }
                                if (icon.isNotEmpty) {
                                  return Row(
                                    children: [
                                      Text(
                                        icon,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              })(),
                              Text(
                                fac.name,
                                style: AppTypography.body.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          // Opening Hours Section
          if (restaurant.openingSlots.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _OpeningHoursSection(
                  openingSlots: restaurant.openingSlots,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Reviews Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ratings & reviews',
                        style: AppTypography.body.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!restaurant.hasUserReviewed)
                        GestureDetector(
                          onTap: _showAddReviewDialog,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.edit,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Write a review',
                                style: AppTypography.body.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Overall Rating
                  InkWell(
                    onTap: restaurant.hasUserReviewed
                        ? null
                        : _showAddReviewDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: AppTypography.headline.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Stars
                          Row(
                            children: List.generate(5, (index) {
                              final rating = restaurant.rating;
                              final filled = index < rating.floor();
                              final halfFilled =
                                  index == rating.floor() && rating % 1 >= 0.5;
                              return Icon(
                                halfFilled
                                    ? Icons.star_half
                                    : filled
                                    ? Icons.star
                                    : Icons.star_border,
                                color: AppColors.success,
                                size: 24,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${restaurant.reviewCount} ratings | ${restaurant.reviewCount} reviews',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Individual Reviews
                  if (reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No reviews yet',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...reviews.map((review) => _ReviewItem(review: review)),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Location Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location',
                        style: AppTypography.body.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant.address,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (restaurant.postcode != null &&
                      restaurant.postcode!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      restaurant.postcode!,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Restaurant Details Section
                  if (restaurant.phoneNumber.isNotEmpty ||
                      restaurant.email != null ||
                      restaurant.website.isNotEmpty) ...[
                    const Divider(height: 24),
                    // Phone
                    if (restaurant.phoneNumber.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            launchUrl(
                              Uri.parse('tel:${restaurant.phoneNumber}'),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  restaurant.phoneNumber,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Email
                    if (restaurant.email != null &&
                        restaurant.email!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            launchUrl(Uri.parse('mailto:${restaurant.email!}'));
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.email,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  restaurant.email!,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Website
                    if (restaurant.website.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            launchUrl(Uri.parse(restaurant.website));
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.language,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  restaurant.website,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),
                  // Map
                  RepaintBoundary(
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.xLarge,
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppShadows.card,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: MapWidget(
                          key: const ValueKey("restaurantMap"),
                          cameraOptions: CameraOptions(
                            center: Point(
                              coordinates: Position(
                                restaurant.longitude,
                                restaurant.latitude,
                              ),
                            ),
                            zoom: 15,
                          ),
                          styleUri: MapboxStyles.LIGHT,
                          onTapListener: (_) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainNavigation(
                                  initialIndex: 1,
                                  initialLatitude: restaurant.latitude,
                                  initialLongitude: restaurant.longitude,
                                ),
                              ),
                              (route) => false,
                            );
                          },
                          onMapCreated: (mapboxMap) async {
                            await _ensureMarkerBytes();
                            final pointManager = await mapboxMap.annotations
                                .createPointAnnotationManager();

                            await pointManager.create(
                              PointAnnotationOptions(
                                geometry: Point(
                                  coordinates: Position(
                                    restaurant.longitude,
                                    restaurant.latitude,
                                  ),
                                ),
                                image: _pinNormalBytes,
                                iconSize: 1.25,
                              ),
                            );

                            // Disable info (i) icon and logo
                            await mapboxMap.attribution.updateSettings(
                              AttributionSettings(enabled: false),
                            );
                            await mapboxMap.logo.updateSettings(
                              LogoSettings(enabled: false),
                            );
                            // Also disable scalebar / compass to keep it clean
                            await mapboxMap.scaleBar.updateSettings(
                              ScaleBarSettings(enabled: false),
                            );
                            await mapboxMap.compass.updateSettings(
                              CompassSettings(enabled: false),
                            );

                            // Disable gestures to make it behave like a static map preview
                            await mapboxMap.gestures.updateSettings(
                              GesturesSettings(
                                scrollEnabled: false,
                                rotateEnabled: false,
                                pinchToZoomEnabled: false,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),

      // Bottom Sticky Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Book Table Button
              Expanded(
                child: AppGradientButton(
                  onPressed: () {
                    if (_authProvider.isGuestMode) {
                      LoginRequiredSheet.show(context);
                      return;
                    }
                    Get.toNamed(
                      AppRoutes.createBooking,
                      arguments: {
                        'restaurantId': int.parse(restaurant.id),
                        'restaurantName': restaurant.name,
                      },
                    );
                  },
                  height: 52,
                  child: Text(
                    'Book Table',
                    style: AppTypography.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Redeem Offer / Loyalty Button
              Expanded(
                child: AppGradientButton(
                  onPressed: () {
                    if (_authProvider.isGuestMode) {
                      LoginRequiredSheet.show(context);
                      return;
                    }
                    if (restaurant.requiresBooking) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            BookingSelectionModal(restaurant: restaurant),
                      );
                    } else {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            RedeemOfferModal(restaurant: restaurant),
                      );
                    }
                  },
                  height: 52,
                  child: Text(
                    (!restaurant.activeDeals.any((d) => d.type != 'none') && restaurant.loyaltyCardEnabled)
                        ? 'Collect Stamp'
                        : 'Redeem Offer',
                    style: AppTypography.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show menu popup
  void _showMenuPopup(
    BuildContext context,
    Restaurant restaurant,
    List<MenuCategory> menuCategories,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          MenuPopup(restaurant: restaurant, menuCategories: menuCategories),
    );
  }
}

/// Review Item Widget
class _ReviewItem extends StatelessWidget {
  final Review review;

  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
                image:
                    review.userProfilePicture != null &&
                        !review.userProfilePicture!.startsWith('assets/')
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          review.userProfilePicture!,
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Builder(
                builder: (context) {
                  final profilePic = review.userProfilePicture;
                  if (profilePic == null) {
                    return Center(
                      child: Icon(
                        Icons.person,
                        size: 24,
                        color: AppColors.textDisabled.withValues(alpha: 0.5),
                      ),
                    );
                  }
                  if (profilePic.startsWith('assets/')) {
                    return ClipOval(
                      child: Image.asset(profilePic, fit: BoxFit.cover),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SizedBox(width: 12),
            // Review Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    review.userName,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rating and Time
                  Row(
                    children: [
                      // Stars
                      Row(
                        children: List.generate(5, (index) {
                          final rating = review.rating.toDouble();
                          final filled = index < rating.floor();
                          final halfFilled =
                              index == rating.floor() && rating % 1 >= 0.5;
                          return Icon(
                            halfFilled
                                ? Icons.star_half
                                : filled
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.success,
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        review.timeAgo,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (review.isVerified) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: AppColors.surface,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (review.comment != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      review.comment!,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Offer Card Widget
class _OfferCard extends StatefulWidget {
  final Discount discount;

  const _OfferCard({required this.discount});

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _isExpanded = false;

  String _getOfferTitle() {
    if (widget.discount.title != null && widget.discount.title!.isNotEmpty) {
      return widget.discount.title!;
    }
    switch (widget.discount.type) {
      case '2for1':
        return '2for1 Drink';
      case 'percentage':
        return '${widget.discount.percentage?.toInt()}% Discount';
      case 'fixed':
        return '£${widget.discount.fixedAmount?.toStringAsFixed(0)} Discount';
      default:
        return widget.discount.displayText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row with Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_offer,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'DEAL',
                        style: AppTypography.title.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              _getOfferTitle(),
              style: AppTypography.body.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDarkest,
                letterSpacing: -0.4,
              ),
            ),
            // Description with Expansion Logic
            if (widget.discount.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.discount.description,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  // Showing "View More" if potentially long
                  if (widget.discount.description.length > 50)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _isExpanded ? 'View Less' : 'View More',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 13,
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Menu Popup Widget - Bottom Sheet
class MenuPopup extends StatelessWidget {
  final Restaurant restaurant;
  final List<MenuCategory> menuCategories;

  const MenuPopup({
    super.key,
    required this.restaurant,
    required this.menuCategories,
  });

  @override
  Widget build(BuildContext context) {
    final bool isImageMenu = restaurant.menuType == 'image';
    final menuImages = restaurant.restaurantImages
        .where((img) => img.imageType == 'menu')
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return GenericBottomSheet(
          title: 'Menu',
          expandChild: true,
          child: _buildMenuContent(
            context,
            scrollController,
            isImageMenu,
            menuImages,
          ),
        );
      },
    );
  }

  Widget _buildMenuContent(
    BuildContext context,
    ScrollController scrollController,
    bool isImageMenu,
    List<RestaurantImage> menuImages,
  ) {
    if (isImageMenu) {
      if (menuImages.isEmpty) {
        return _buildEmptyState();
      }
      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: menuImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                menuImages[index].image.urlFor(fullScreen: true) ?? '',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 300,
                    color: AppColors.cardBackground,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: AppColors.cardBackground,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    }

    if (menuCategories.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: menuCategories.length,
      itemBuilder: (context, categoryIndex) {
        final category = menuCategories[categoryIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Padding(
              padding: EdgeInsets.only(
                bottom: 12,
                top: categoryIndex > 0 ? 24 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: AppTypography.body.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (category.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Menu Items
            ...category.items.map((item) => _MenuItemCard(item: item)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No menu available',
        style: AppTypography.body.copyWith(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Menu Item Card Widget
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textDisabled.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Item Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name
              Padding(
                padding: const EdgeInsets.only(
                  right: 80,
                ), // Space for symbol + price
                child: Text(
                  item.name,
                  style: AppTypography.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Description
              if (item.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    right: 80,
                  ), // Space for symbol + price
                  child: Text(
                    item.description,
                    style: AppTypography.body.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Tags and Price Row
              Row(
                children: [
                  // Dietary Tags
                  if (item.isVegan)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'VG',
                        style: AppTypography.body.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  if (item.isGlutenFree)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'GF',
                        style: AppTypography.body.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
              // Availability
              if (!item.isAvailable)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Currently unavailable',
                    style: AppTypography.body.copyWith(
                      fontSize: 12,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          // Vegetarian Symbol at top right
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '£${item.price}',
                  style: AppTypography.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                _VegetarianSymbol(isVegetarian: item.isVegetarian),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vegetarian Symbol Widget - Green circle inside green square (like packaging symbol)
class _VegetarianSymbol extends StatelessWidget {
  final bool isVegetarian;

  const _VegetarianSymbol({required this.isVegetarian});

  @override
  Widget build(BuildContext context) {
    final color = isVegetarian ? AppColors.success : Colors.red;
    final darkColor = isVegetarian
        ? AppColors.success.withValues(alpha: 0.9)
        : Colors.red.shade700;

    return Container(
      width: 15,
      height: 15,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer square outline
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              border: Border.all(color: darkColor, width: 1.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Inner filled circle
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

/// Opening Hours Section Widget
class _OpeningHoursSection extends StatefulWidget {
  final List<OpeningSlot> openingSlots;

  const _OpeningHoursSection({required this.openingSlots});

  @override
  State<_OpeningHoursSection> createState() => _OpeningHoursSectionState();
}

class _OpeningHoursSectionState extends State<_OpeningHoursSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;

    final currentDay = DateFormat('EEEE').format(DateTime.now());
    final todayIndex = widget.openingSlots.indexWhere(
      (slot) => slot.dayName.toLowerCase() == currentDay.toLowerCase(),
    );

    if (todayIndex < 0) return;

    const itemWidth = 112.0; // 100 width + 12 right margin
    final targetOffset = (todayIndex * itemWidth).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool _isRestaurantClosed(List<OpeningSlot> slots) {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now);
    final currentTime = TimeOfDay.now();

    // Find today's slot
    final todaySlot = slots.firstWhere(
      (slot) => slot.dayName.toLowerCase() == currentDay.toLowerCase(),
      orElse: () => null as dynamic,
    );

    if ((todaySlot).isClosed) return true;

    // Parse closing time and compare
    try {
      final closingParts = todaySlot.closingTime.split(':');
      final closingHour = int.parse(closingParts[0]);
      final closingMinute = closingParts.length > 1
          ? int.parse(closingParts[1])
          : 0;
      final closingTime = TimeOfDay(hour: closingHour, minute: closingMinute);

      return currentTime.hour > closingTime.hour ||
          (currentTime.hour == closingTime.hour &&
              currentTime.minute >= closingMinute);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = DateFormat('EEEE').format(DateTime.now());
    final isClosed = _isRestaurantClosed(widget.openingSlots);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.access_time_filled,
              color: AppColors.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Opening Hours',
                style: AppTypography.body.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isClosed)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Closed',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.openingSlots.length,
            itemBuilder: (context, index) {
              final slot = widget.openingSlots[index];
              final isToday =
                  slot.dayName.toLowerCase() == currentDay.toLowerCase();

              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.success.withValues(alpha: 0.05)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isToday
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.textDisabled.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slot.dayName.substring(0, 3), // Mon, Tue, etc.
                      style: AppTypography.body.copyWith(
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                        color: isToday
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (slot.isClosed)
                      Text(
                        'Closed',
                        style: AppTypography.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade400,
                        ),
                      )
                    else ...[
                      Text(
                        slot.openingTime,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slot.closingTime,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddReviewDialog extends StatefulWidget {
  final int restaurantId;
  final Function(int rating, String comment) onSubmit;

  const _AddReviewDialog({required this.restaurantId, required this.onSubmit});

  @override
  State<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<_AddReviewDialog> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a comment')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(_rating, _commentController.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Write a Review',
        style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Comment',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: AppTypography.bodySmall.copyWith(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTypography.bodySmall.copyWith(color: Colors.grey),
          ),
        ),
        AppGradientButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          height: 44,
          width: 100,
          borderRadius: BorderRadius.circular(10),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Submit',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
}

class _LoyaltyCardSection extends StatelessWidget {
  final LoyaltyProgram loyaltyProgram;
  final bool isGuestMode;

  const _LoyaltyCardSection({
    required this.loyaltyProgram,
    required this.isGuestMode,
  });

  @override
  Widget build(BuildContext context) {
    if (!loyaltyProgram.loyaltyCardEnabled) return const SizedBox.shrink();

    final isEligible = loyaltyProgram.isRewardEligible;
    final completed = isGuestMode ? 0 : loyaltyProgram.completedRedemptions;
    final requiredVal = loyaltyProgram.requiredRedemptions;

    final baseColor = isEligible ? const Color(0xFFF59E0B) : const Color(0xFF7C3AED);

    return Container(
      decoration: BoxDecoration(
        gradient: isEligible
            ? const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEligible ? Icons.emoji_events_rounded : Icons.stars_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEligible ? 'Loyalty Reward Unlocked!' : 'Loyalty Card Program',
                  style: AppTypography.title.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isEligible)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'REDEEMABLE',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFFD97706),
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loyaltyProgram.rewardDescription,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isEligible) ...[
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'REWARD UNLOCKED',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (loyaltyProgram.rewardQrCode != null && loyaltyProgram.rewardQrCode!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        loyaltyProgram.rewardQrCode!
                            .replaceAll('http://127.0.0.1:8000', Environment.baseUrl)
                            .replaceAll('http://localhost:8000', Environment.baseUrl),
                        width: 160,
                        height: 160,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            width: 160,
                            height: 160,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: AppColors.cardBorder,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.qr_code_2_rounded,
                                size: 54,
                                color: AppColors.textDisabled,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (loyaltyProgram.rewardCode != null && loyaltyProgram.rewardCode!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loyaltyProgram.rewardCode!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Ask the merchant to scan this QR code to claim your free reward.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ] else ...[
            if (requiredVal > 0 && requiredVal <= 12) ...[
              _buildStampGrid(completed, requiredVal, isEligible),
              const SizedBox(height: 14),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: requiredVal > 0 ? (completed / requiredVal) : 0.0,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isGuestMode
                      ? 'Progress: 0 of $requiredVal completed'
                      : loyaltyProgram.progressText.isNotEmpty
                          ? loyaltyProgram.progressText
                          : 'Progress: $completed of $requiredVal completed',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                if (!isGuestMode)
                  Text(
                    '${requiredVal - completed} left',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
          if (isGuestMode) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Login to track progress and earn this reward!',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ] else if (!isEligible) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total lifetime redemptions: ${loyaltyProgram.totalLifetimeRedemptions}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
                if (loyaltyProgram.rewardsEarned > 0)
                  Text(
                    'Rewards earned: ${loyaltyProgram.rewardsEarned}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStampGrid(int completed, int requiredVal, bool isEligible) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: List.generate(requiredVal, (index) {
        final isCompleted = index < completed;
        final isLast = index == requiredVal - 1;

        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isCompleted 
                ? Colors.white 
                : Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: isCompleted 
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? Icon(
                  Icons.check_rounded,
                  color: isEligible ? const Color(0xFFD97706) : const Color(0xFF7C3AED),
                  size: 20,
                  weight: 3.0,
                )
              : isLast
                  ? Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 16,
                    )
                  : Text(
                      '${index + 1}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
        );
      }),
    );
  }
}
