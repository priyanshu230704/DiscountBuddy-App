import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'main_navigation.dart';
import '../models/restaurant.dart';
import '../models/restaurant_detail.dart';
import '../models/review.dart';
import '../models/menu_item.dart';
import '../services/restaurant_service.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/generic_bottom_sheet.dart';
import 'deals/redeem_offer_modal.dart';
import 'bookings/booking_selection_modal.dart';
import 'bookings/create_booking_page.dart';
import '../models/mystery_visit.dart';
import '../services/mystery_guest_service.dart';
import '../providers/auth_provider.dart';
import 'mystery_guest/mystery_audit_modal.dart';
import '../widgets/occupancy_tag.dart';

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
  final MysteryGuestService _mysteryGuestService = MysteryGuestService();
  final AuthProvider _authProvider = AuthProvider();

  RestaurantDetail? _restaurantDetail;
  MysteryVisit? _activeVisit;
  List<MysteryVisit> _allVisits = [];
  bool _isMysteryGuest = false;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _errorMessage;

  ui.Image? _appLogoImage;
  Uint8List? _pinNormalBytes;

  @override
  void initState() {
    super.initState();
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
    // Mapbox map doesn't need manual dispose for the controller here
    super.dispose();
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
    final innerCirclePaint = Paint()..color = const Color(0xFFF8F9FC);
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
      final restaurantDetail = await _restaurantService
          .getRestaurantDetailBySlug(
            widget.slug,
            latitude: widget.latitude,
            longitude: widget.longitude,
          );
      setState(() {
        _restaurantDetail = restaurantDetail;
        _isFavorite = restaurantDetail.restaurant.isFavourite;
        _isLoading = false;
      });

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

  // Convert km to miles
  double _kmToMiles(double km) {
    return km * 0.621371;
  }

  // Get opening hours (using restaurant opening hours or default)
  String _getOpeningHours(Restaurant restaurant) {
    if (restaurant.openingHours.isNotEmpty) {
      // Extract closing time from first opening hour string
      final firstHour = restaurant.openingHours[0];
      if (firstHour.contains('-')) {
        final parts = firstHour.split('-');
        if (parts.length > 1) {
          return 'Open until ${parts[1].trim()}';
        }
      }
      return firstHour;
    }
    return 'Open until 22:00';
  }

  // Get price range from restaurant data
  String _getPriceRange(Restaurant restaurant) {
    final priceRange = restaurant.priceRange ?? 2;
    // Convert price range (1-4) to £ symbols
    return '£' * priceRange;
  }

  // Toggle favorite status
  Future<void> _toggleFavorite() async {
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
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _restaurantDetail == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(title: const Text('Restaurant Details')),
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
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRestaurant,
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
    final dist = restaurant.distanceMiles ?? _kmToMiles(restaurant.distance);

    return Scaffold(
      backgroundColor: AppColors.surface,

      body: CustomScrollView(
        cacheExtent:
            500, // Limit off-screen rendering to reduce memory pressure
        slivers: [
          // Header with full-width image and gradient
          SliverAppBar(
            expandedHeight: 300,
            pinned: false,
            backgroundColor: AppColors.surface,
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
                    CachedNetworkImage(
                      imageUrl: restaurant.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.textDisabled,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.textDisabled,
                        child: const Icon(Icons.restaurant, size: 64),
                      ),
                    ),
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
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
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
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Details Rows
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Cuisine and Location
                      Row(
                        children: [
                          Text(
                            restaurant.cuisine,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 14,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: AppColors.textDisabled,
                          ),
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${restaurant.address.split(',').first} (${dist.toStringAsFixed(2)} miles)',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Row 2: Price and Timing
                      Row(
                        children: [
                          Text(
                            _getPriceRange(restaurant),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            ' ${_getOpeningHours(restaurant)}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textPrimary,
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
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _showMenuPopup(context, menuCategories);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.menu,
                                    color: AppColors.textPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Menu',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                          border: Border.all(
                            color: AppColors.textDisabled.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                          border: Border.all(
                            color: AppColors.textDisabled.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final message =
                                  'Check out this deal at ${restaurant.name}!\n\n'
                                  '${restaurant.discount.displayText} - ${restaurant.discount.description}\n\n'
                                  '📍 ${restaurant.address}\n'
                                  'Found on DiscountBuddy';
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
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
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
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showMysteryAuditModal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _activeVisit!.status == 'assigned'
                                ? 'Start Audit'
                                : 'Continue Audit',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                                      style: GoogleFonts.inter(
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
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      Text(
                                        '${v.overallScore!.toStringAsFixed(1)}/100',
                                        style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Offer Card Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (restaurant.activeDeals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Active Offers 📢',
                      style: GoogleFonts.inter(
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
                    child: _OfferCard(discount: restaurant.discount),
                  ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 17)),
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
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddReviewDialog,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Write a review'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Overall Rating
                  InkWell(
                    onTap: _showAddReviewDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (restaurant.postcode != null &&
                      restaurant.postcode!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      restaurant.postcode!,
                      style: GoogleFonts.inter(
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
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Email
                    if (restaurant.email != null &&
                        restaurant.email!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Website
                    if (restaurant.website.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.language,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Open website URL
                                },
                                child: Text(
                                  restaurant.website,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textDisabled.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
          color: AppColors.surface,
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
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateBookingPage(
                          restaurantId: int.parse(restaurant.id),
                          restaurantName: restaurant.name,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Book Table',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Redeem Offer Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Redeem Offer',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
  void _showMenuPopup(BuildContext context, List<MenuCategory> menuCategories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuPopup(menuCategories: menuCategories),
    );
  }
}

/// Review Item Widget
class _ReviewItem extends StatelessWidget {
  final Review review;

  const _ReviewItem({required this.review});

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

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
              ),
              child: Center(
                child: Text(
                  _getInitials(review.userName),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
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
                    style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
class _OfferCard extends StatelessWidget {
  final Discount discount;

  const _OfferCard({required this.discount});

  String _getOfferTitle() {
    if (discount.title != null && discount.title!.isNotEmpty) {
      return discount.title!;
    }
    switch (discount.type) {
      case '2for1':
        return '2for1 Drink';
      case 'percentage':
        return '${discount.percentage?.toInt()}% Discount';
      case 'fixed':
        return '£${discount.fixedAmount?.toStringAsFixed(0)} Discount';
      default:
        return discount.displayText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Info Icon
          Row(
            children: [
              Expanded(
                child: Text(
                  _getOfferTitle(),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            discount.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Menu Popup Widget - Bottom Sheet
class MenuPopup extends StatelessWidget {
  final List<MenuCategory> menuCategories;

  const MenuPopup({super.key, required this.menuCategories});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return GenericBottomSheet(
          title: 'Menu',
          expandChild: true,
          child: menuCategories.isEmpty
              ? Center(
                  child: Text(
                    'No menu available',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
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
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (category.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  category.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Menu Items
                        ...category.items.map(
                          (item) => _MenuItemCard(item: item),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
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
                  style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
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
class _OpeningHoursSection extends StatelessWidget {
  final List<OpeningSlot> openingSlots;

  const _OpeningHoursSection({required this.openingSlots});

  @override
  Widget build(BuildContext context) {
    final currentDay = DateFormat('EEEE').format(DateTime.now());

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
            Text(
              'Opening Hours',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: openingSlots.length,
            itemBuilder: (context, index) {
              final slot = openingSlots[index];
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
                      style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade400,
                        ),
                      )
                    else ...[
                      Text(
                        slot.openingTime,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slot.closingTime,
                        style: GoogleFonts.inter(
                          fontSize: 11,
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
        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: GoogleFonts.inter(color: Colors.grey),
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
          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Submit', style: GoogleFonts.inter()),
        ),
      ],
    );
  }
}
