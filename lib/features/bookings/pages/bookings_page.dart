import 'package:discount_buddy/features/home/pages/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:discount_buddy/core/utils/date_time_utils.dart';
import 'package:discount_buddy/core/theme/app_design.dart';
import 'package:get/get.dart';

import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/components/layout.dart';
import 'package:discount_buddy/components/buttons.dart';
import 'package:discount_buddy/features/deals/models/deal_redemption.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';
import 'package:discount_buddy/features/restaurants/data/restaurant_service.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';
import 'package:discount_buddy/widgets/loading_widget.dart';
import 'package:discount_buddy/widgets/empty_state_widget.dart';
import 'package:discount_buddy/widgets/generic_bottom_sheet.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'package:discount_buddy/features/nearby/data/location_service.dart';
import 'package:discount_buddy/core/utils/media_url_utils.dart';

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
  double? _userLat;
  double? _userLon;


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
          _userLat = lat;
          _userLon = lon;
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

  Future<void> _deleteBooking(int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _restaurantService.deleteBooking(bookingId);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e')),
          );
        }
      }
    }
  }

  Future<void> _editBooking(Booking booking) async {
    // Show a simplified edit dialog
    final TextEditingController guestsController = 
        TextEditingController(text: booking.numberOfGuests.toString());
    final TextEditingController requestController = 
        TextEditingController(text: booking.specialRequests);
    
    final localBooking = booking.bookingDate.toLocal();
    DateTime selectedDate = localBooking;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(localBooking);
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Reservation'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: guestsController,
                  decoration: const InputDecoration(labelText: 'Number of Guests'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: requestController,
                  decoration: const InputDecoration(labelText: 'Special Requests'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          DateTimeUtils.formatDateOnly(selectedDate),
                        ),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(
                          DateTimeUtils.formatTimeOfDay24h(selectedTime),
                        ),
                        onPressed: () async {
                          final time = await DateTimeUtils.showTimePicker24h(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'update': true,
              'date': DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              ),
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && result['update'] == true) {
      setState(() => _isLoading = true);
      try {
        await _restaurantService.updateBooking(
          bookingId: booking.id,
          bookingDate: result['date'] as DateTime,
          numberOfGuests: int.tryParse(guestsController.text),
          specialRequests: requestController.text,
        );
        await _loadData();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e')),
          );
        }
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
              labelStyle: AppTypography.body.copyWith(
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
                                  userLat: _userLat,
                                  userLon: _userLon,
                                  onExplorePressed: () {
                                    // Navigation to explore restaurants
                                  },
                                ),
                              )
                            : _BookingList(
                                bookings: _bookings,
                                onRefresh: _loadData,
                                onEdit: _editBooking,
                                onDelete: _deleteBooking,
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
    this.userLat,
    this.userLon,
  });

  final List<Restaurant> trendingItems;
  final VoidCallback onExplorePressed;
  final double? userLat;
  final double? userLon;

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
                  style: AppTypography.title.copyWith(
                    fontSize: 20, // Match section titles (20px)
                    fontWeight: FontWeight.w700,
                  ),
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
                  onPressed: () {
                    MainNavigationState.of(context)?.changeIndex(0);
                  },
                  width: double.infinity,
                  height: 54,
                  child: const Text('Explore restaurants'),
                ),
              ],
            ),
          ),
        ],
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
                      redemption.restaurantName,
                      style: AppTypography.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      redemption.isLoyaltyOnly
                          ? 'Loyalty Stamp'
                          : (redemption.deal?.title ?? 'Deal'),
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
                'Claimed: ${DateTimeUtils.formatDateTime24h(redemption.usedAt)}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          if (redemption.redeemedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Redeemed: ${DateTimeUtils.formatDateTime24h(redemption.redeemedAt!)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => GenericBottomSheet(
          title: redemption.restaurantName,
          showHandle: false,
          centerTitle: true,
          showCloseButton: true,
          expandChild: true,
          footer: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: SecondaryButton(
              label: 'View restaurant',
              onPressed: () {
                Navigator.pop(context);
                Get.toNamed(
                  AppRoutes.restaurantDetails,
                  arguments: {
                    'slug': redemption.restaurantId.toString(),
                    'latitude': null,
                    'longitude': null,
                  },
                );
              },
            ),
          ),
          child: _RedemptionDetailContent(
            redemption: redemption,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

class _RedemptionDetailContent extends StatelessWidget {
  final DealRedemption redemption;
  final ScrollController scrollController;

  const _RedemptionDetailContent({
    required this.redemption,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final qrUrl = redemption.qrCodeUrl != null && redemption.qrCodeUrl!.isNotEmpty
        ? resolveApiMediaUrl(redemption.qrCodeUrl!)
        : null;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      children: [
        Center(
          child: _StatusBadge(
            isConfirmed: redemption.restaurantConfirmed,
          ),
        ),
        if (qrUrl != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Image.network(
                qrUrl,
                width: 180,
                height: 180,
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
        ],
        if (redemption.redemptionCode != null) ...[
          const SizedBox(height: AppSpacing.lg),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _DetailRow(
          icon: Icons.local_offer,
          label: 'Offer',
          value: redemption.isLoyaltyOnly
              ? 'Loyalty Stamp'
              : (redemption.deal?.title ?? 'Deal'),
        ),
        if (!redemption.isLoyaltyOnly && redemption.deal?.discountPercentage != null) ...[
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.percent,
            label: 'Discount',
            value:
                '${redemption.deal!.discountPercentage!.toStringAsFixed(0)}% OFF',
          ),
        ],
        if (!redemption.isLoyaltyOnly && redemption.deal?.discountAmount != null) ...[
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.attach_money,
            label: 'Fixed discount',
            value: '£${redemption.deal!.discountAmount}',
          ),
        ],
        if (redemption.restaurantConfirmed &&
            redemption.finalBillAmount != null) ...[
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 16),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.receipt_long,
            label: 'Total Bill',
            value: '£${redemption.price?.toStringAsFixed(2) ?? '0.00'}',
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.savings,
            label: 'Total Saved',
            value:
                '£${redemption.discountAmountSaved?.toStringAsFixed(2) ?? '0.00'}',
            valueColor: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.payments,
            label: 'Final Amount Paid',
            value:
                '£${redemption.finalBillAmount?.toStringAsFixed(2) ?? '0.00'}',
            isBold: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.people,
            label: 'Number of People',
            value: '${redemption.peopleCount ?? 1}',
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 16),
        ],
        const SizedBox(height: AppSpacing.md),
        _DetailRow(
          icon: Icons.calendar_today,
          label: 'Claimed on',
          value: DateTimeUtils.formatDateTime24h(redemption.usedAt),
        ),
        if (redemption.redeemedAt != null) ...[
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.verified_rounded,
            label: 'Redeemed on',
            value: DateTimeUtils.formatDateTime24h(redemption.redeemedAt!),
            valueColor: const Color(0xFF10B981),
          ),
        ],
        if (redemption.notes != null && redemption.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.note,
            label: 'Notes',
            value: redemption.notes!,
          ),
        ],
      ],
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
  final Function(Booking) onEdit;
  final Function(int) onDelete;

  const _BookingList({
    required this.bookings,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
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
          return _BookingCard(
            booking: sortedBookings[index],
            onEdit: () => onEdit(sortedBookings[index]),
            onDelete: () => onDelete(sortedBookings[index].id),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookingCard({
    required this.booking,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final whenLabel = DateTimeUtils.formatDateTime24h(booking.bookingDate);

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
              const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  whenLabel,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.people, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${booking.numberOfGuests} guests',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          if (booking.specialRequests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Requests: ${booking.specialRequests}',
              style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          if ((booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed) &&
              booking.bookingDate.isAfter(DateTime.now())) ...[
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
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
