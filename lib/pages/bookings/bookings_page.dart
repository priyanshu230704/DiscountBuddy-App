import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../../components/app_app_bar.dart';
import '../../components/layout.dart';
import '../../components/buttons.dart';
import '../../models/deal_redemption.dart';
import '../../models/user_interactions.dart';
import '../../services/restaurant_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_gradient_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/restaurant.dart';
import '../../services/location_service.dart';
import '../restaurant_details_page.dart';

/// Bookings/Redemptions Screen - Integrated with deal uses API
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  // Distance calculation is handled, but dist variable itself is not used currently
  // keeping it commented if needed, or just remove if we use it elsewhere
  // final dist = restaurant.distanceMiles ?? _kmToMiles(restaurant.distance);
  List<DealRedemption> _redemptions = [];
  List<Booking> _bookings = [];
  bool _isLoading = true;
  late TabController _tabController;
  List<Restaurant> _trendingRestaurants = [];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Get location for distance calculation
      double? lat, lon;
      try {
        final position = await _locationService.getCurrentLocation();
        lat = position.latitude;
        lon = position.longitude;
      } catch (e) {
        debugPrint('Location fetching failed for bookings: $e');
      }

      // Load redemptions, bookings and trending restaurants in parallel
      final results = await Future.wait([
        _restaurantService.getUserDealRedemptions(),
        _restaurantService.getRestaurants(latitude: lat, longitude: lon),
        _restaurantService.getUserBookings(),
      ]);

      if (mounted) {
        setState(() {
          _redemptions = results[0] as List<DealRedemption>;
          _trendingRestaurants = results[1] as List<Restaurant>;
          _bookings = results[2] as List<Booking>;
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load activity: $e')));
      }
    }
  }

  List<DealRedemption> _getRedemptionsByTab(int index) {
    // Sort by date descending
    final sortedList = List<DealRedemption>.from(_redemptions)
      ..sort((a, b) => b.usedAt.compareTo(a.usedAt));

    switch (index) {
      case 1: // Active Coupons
        return sortedList.where((r) => !r.restaurantConfirmed).toList();
      case 2: // Claimed Coupons
        return sortedList.where((r) => r.restaurantConfirmed).toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
        appBar: AppAppBar(
          titleText: 'My activity', 
          centerTitle: false,
          backgroundColor: Colors.transparent,
        ),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.only(top: 2),
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent, // Fix: Remove Material 3 underline in TabBar
              labelStyle: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Reservations'),
                Tab(text: 'Active coupons'),
                Tab(text: 'Claimed coupons'),
              ],
            ),
            // const Divider(height: 1), // Fix: Removed unwanted black line below TabBar
            Expanded(
              child: _isLoading
                  ? const LoadingWidget(message: 'Loading your activity...')
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _bookings.isEmpty
                            ? RefreshIndicator(
                                onRefresh: _loadData,
                                child: _ReservationEmptyTab(
                                  trendingItems: _trendingRestaurants,
                                  onExplorePressed: () {
                                    // Navigation to explore restaurants
                                  },
                                ),
                              )
                            : _BookingList(
                                bookings: _bookings,
                                onRefresh: _loadData,
                              ),

                        _RedemptionList(
                          redemptions: _getRedemptionsByTab(1),
                          onRefresh: _loadData,
                          emptyMessage: 'No active coupons',
                        ),
                        _RedemptionList(
                          redemptions: _getRedemptionsByTab(2),
                          onRefresh: _loadData,
                          emptyMessage: 'No claimed coupons',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

class _ReservationEmptyTab extends StatelessWidget {
  const _ReservationEmptyTab({
    required this.trendingItems,
    required this.onExplorePressed,
  });

  final List<Restaurant> trendingItems;
  final VoidCallback onExplorePressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'No reservations yet',
                  style: AppTypography.title.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Find a restaurant and book a table in seconds.',
                  textAlign: TextAlign.center,
                  style: AppTypography.subtitle,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppGradientButton(
                  onPressed: onExplorePressed,
                  width: double.infinity,
                  height: 54,
                  child: const Text('Explore restaurants'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Text(
                'Trending near you',
                style: AppTypography.title,
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 248, // Increased from 238 to fix overflow
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trendingItems.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
              itemBuilder: (context, index) =>
                  _TrendingCard(item: trendingItems[index]),
            ),
          ),
        ],
      ),
    );
  }
}



class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.item});

  final Restaurant item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailsPage(
                slug: item.id,
              ),
            ),
          );
        },
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 118,
              child: Stack(
                children: [
                  item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(Icons.restaurant, color: Color(0xFFD1D5DB), size: 40),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(Icons.restaurant, color: Color(0xFFD1D5DB), size: 40),
                        ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.discount.type == 'none' ? 'Special Deal' : item.discount.description,
                            style: AppTypography.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Limited time',
                            style: AppTypography.caption.copyWith(
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFBBF24),
                        size: 15,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${item.reviewCount} reviews',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                   Text(
                    item.cuisine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${(item.distanceMiles ?? item.distance * 0.621371).toStringAsFixed(1)} miles away',
                        style: AppTypography.bodySmall,
                      ),
                    ],
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
}

class _RedemptionList extends StatelessWidget {
  final List<DealRedemption> redemptions;
  final Future<void> Function() onRefresh;
  final String emptyMessage;

  const _RedemptionList({
    required this.redemptions,
    required this.onRefresh,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (redemptions.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyStateWidget(
              icon: Icons.local_offer_outlined,
              title: emptyMessage,
              message: 'Pull to refresh or explore restaurants to get started.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          100,
        ),
        itemCount: redemptions.length,
        itemBuilder: (context, index) {
          return _RedemptionCard(redemption: redemptions[index]);
        },
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  final DealRedemption redemption;

  const _RedemptionCard({required this.redemption});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      onTap: () => _showRedemptionDetails(context, redemption),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      redemption.deal.restaurantName,
                      style: AppTypography.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      redemption.deal.title,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StatusBadge(isConfirmed: redemption.restaurantConfirmed),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Used: ${DateFormat('MMM d, yyyy HH:mm').format(redemption.usedAt)}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          if (redemption.redemptionCode != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.qr_code,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Code: ${redemption.redemptionCode}',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRedemptionDetails(BuildContext context, DealRedemption redemption) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RedemptionDetailModal(redemption: redemption),
    );
  }
}

class _RedemptionDetailModal extends StatelessWidget {
  final DealRedemption redemption;
  const _RedemptionDetailModal({required this.redemption});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              redemption.deal.restaurantName,
                              style: AppTypography.title.copyWith(
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _StatusBadge(
                              isConfirmed: redemption.restaurantConfirmed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // QR Code Logic
                      if (redemption.qrCodeUrl != null &&
                          redemption.qrCodeUrl!.isNotEmpty) ...[
                        Center(
                          child: AppCard(
                            padding:
                                const EdgeInsets.all(AppSpacing.lg),
                            child: Image.network(
                              redemption.qrCodeUrl!
                                  .replaceAll('localhost', '10.0.2.2')
                                  .replaceAll('127.0.0.1', '10.0.2.2'),
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) {
                                return const Icon(
                                  Icons.broken_image,
                                  size: 64,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      if (redemption.redemptionCode != null) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.large,
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: AppShadows.card,
                            ),
                            child: Text(
                              redemption.redemptionCode!,
                              style: AppTypography.title.copyWith(
                                fontSize: 24,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],

                      _DetailRow(
                        icon: Icons.local_offer,
                        label: 'Offer',
                        value: redemption.deal.title,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (redemption.deal.discountPercentage != null)
                        _DetailRow(
                          icon: Icons.percent,
                          label: 'Discount',
                          value:
                              '${redemption.deal.discountPercentage!.toStringAsFixed(0)}% OFF',
                        ),
                      if (redemption.deal.discountAmount != null)
                        _DetailRow(
                          icon: Icons.attach_money,
                          label: 'Fixed discount',
                          value: '£${redemption.deal.discountAmount}',
                        ),

                      if (redemption.restaurantConfirmed && redemption.finalBillAmount != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(),
                        const SizedBox(height: AppSpacing.lg),
                        _DetailRow(
                          icon: Icons.receipt_long,
                          label: 'Total Bill',
                          value: '£${redemption.price?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailRow(
                          icon: Icons.savings,
                          label: 'Total Saved',
                          value: '£${redemption.discountAmountSaved?.toStringAsFixed(2) ?? '0.00'}',
                          valueColor: AppColors.success,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailRow(
                          icon: Icons.payments,
                          label: 'Final Amount Paid',
                          value: '£${redemption.finalBillAmount?.toStringAsFixed(2) ?? '0.00'}',
                          isBold: true,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailRow(
                          icon: Icons.people,
                          label: 'Number of People',
                          value: '${redemption.peopleCount ?? 1}',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(),
                      ],

                      const SizedBox(height: AppSpacing.lg),
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: 'Used on',
                        value: DateFormat(
                          'EEEE, MMM d, yyyy HH:mm',
                        ).format(redemption.usedAt),
                      ),

                      if (redemption.notes != null &&
                          redemption.notes!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _DetailRow(
                          icon: Icons.note,
                          label: 'Notes',
                          value: redemption.notes!,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
              SecondaryButton(
                label: 'View restaurant',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailsPage(
                        slug: redemption.restaurantId.toString(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  Widget _buildValue(String text) {
    return Text(
      text,
      style: AppTypography.body.copyWith(
        fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
        color: valueColor ?? AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildValue(value),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isConfirmed;

  const _StatusBadge({required this.isConfirmed});

  @override
  Widget build(BuildContext context) {
    // If restaurant_confirmed is true -> Confirmed (Green)
    // If false -> Pending/Active (Orange)

    final color = isConfirmed
        ? AppColors.success
        : AppColors.discount;
    final text = isConfirmed ? 'Confirmed' : 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
class _BookingList extends StatelessWidget {
  final List<Booking> bookings;
  final Future<void> Function() onRefresh;

  const _BookingList({
    required this.bookings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by date descending
    final sortedBookings = List<Booking>.from(bookings)
      ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          100,
        ),
        itemCount: sortedBookings.length,
        itemBuilder: (context, index) {
          return _BookingCard(booking: sortedBookings[index]);
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(booking.bookingDate);
    final timeStr = DateFormat('HH:mm').format(booking.bookingDate);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.restaurantName,
                      style: AppTypography.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      booking.restaurantCityName ?? '',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              _BookingStatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text('$dateStr at $timeStr', style: AppTypography.bodySmall),
              const Spacer(),
              const Icon(Icons.people, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text('${booking.numberOfGuests} guests', style: AppTypography.bodySmall),
            ],
          ),
          if (booking.specialRequests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Requests: ${booking.specialRequests}',
              style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _BookingStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case BookingStatus.confirmed:
        color = AppColors.success;
        label = 'Confirmed';
        break;
      case BookingStatus.pending:
        color = AppColors.discount;
        label = 'Pending';
        break;
      case BookingStatus.cancelled:
        color = AppColors.error;
        label = 'Cancelled';
        break;
      case BookingStatus.completed:
        color = AppColors.primary;
        label = 'Visited';
        break;
    }


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
