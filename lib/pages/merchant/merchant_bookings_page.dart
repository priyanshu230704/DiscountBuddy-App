import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:discount_buddy/utils/date_time_utils.dart';
import '../../widgets/empty_state_widget.dart';
import '../../components/layout.dart' show AppCard;
import '../../services/merchant_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../components/app_app_bar.dart';
import '../../widgets/skeleton_loader.dart';
import 'arrived_dialog.dart';
import 'noshow_dialog.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

/// Title case for booking status in the details dialog (matches value weight, not all-caps).
String _formatBookingStatusForDialog(dynamic raw) {
  final t = (raw ?? 'pending').toString().trim().toLowerCase();
  if (t.isEmpty) return 'Pending';
  return '${t[0].toUpperCase()}${t.substring(1)}';
}

class MerchantBookingsPage extends StatefulWidget {
  final int? restaurantId;
  const MerchantBookingsPage({super.key, this.restaurantId});

  @override
  State<MerchantBookingsPage> createState() => _MerchantBookingsPageState();
}

class _MerchantBookingsPageState extends State<MerchantBookingsPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _restaurants = [];
  int? _selectedRestaurantId;
  bool _isLoading = true;
  bool _isFetching = false;
  bool _isLoadingRestaurants = true;
  String _selectedStatus = 'pending';

  List<Map<String, dynamic>> get _filteredBookings {
    return _bookings.where((b) {
      final s = (b['status'] ?? 'pending').toString().toLowerCase();
      return s == _selectedStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedRestaurantId = widget.restaurantId;
    _loadRestaurants();
    _loadBookings();
  }

  Future<void> _loadRestaurants() async {
    try {
      setState(() => _isLoadingRestaurants = true);
      final restaurants = await _merchantService.getMerchantRestaurants();
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          _isLoadingRestaurants = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRestaurants = false);
      }
    }
  }

  Future<void> _loadBookings() async {
    if (_isFetching) return;

    try {
      setState(() {
        _isLoading = true;
        _isFetching = true;
      });

      final bookings = await _merchantService.getMerchantBookings(
        restaurantId: _selectedRestaurantId,
      );
      // Sort: Pending first, then by date desc
      bookings.sort((a, b) {
        final statusA = (a['status'] ?? '').toString().toLowerCase();
        final statusB = (b['status'] ?? '').toString().toLowerCase();

        if (statusA == 'pending' && statusB != 'pending') return -1;
        if (statusA != 'pending' && statusB == 'pending') return 1;

        final dateA =
            DateTimeUtils.tryParseBookingInstant(a['booking_date']) ??
            DateTime(0);
        final dateB =
            DateTimeUtils.tryParseBookingInstant(b['booking_date']) ??
            DateTime(0);
        return dateB.compareTo(dateA);
      });
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookings: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        _isFetching = false;
      }
    }
  }

  Future<void> _reviewBooking(int id, String status) async {
    try {
      await _merchantService.reviewBooking(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking ${status == 'confirmed' ? 'confirmed' : 'rejected'} successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markBookingArrived(int id, String arrivalTime) async {
    try {
      await _merchantService.markBookingArrived(id, arrivalTime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest marked as arrived successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark arrived: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markBookingNoShow(int id, String reason, String notes) async {
    try {
      await _merchantService.markBookingNoShow(id, reason, notes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest marked as No-Show successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark no-show: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showArrivedDialog(int bookingId) {
    final booking = _bookings.firstWhere(
      (b) => (b['booking_id'] ?? b['id']) == bookingId,
    );
    showDialog(
      context: context,
      builder: (context) => ArrivedDialog(
        booking: booking,
        onConfirm: (arrivalTime) {
          _markBookingArrived(bookingId, arrivalTime);
        },
      ),
    );
  }

  void _showNoShowDialog(int bookingId) {
    final booking = _bookings.firstWhere(
      (b) => (b['booking_id'] ?? b['id']) == bookingId,
    );
    showDialog(
      context: context,
      builder: (context) => NoShowDialog(
        booking: booking,
        onConfirm: (reason, notes) {
          _markBookingNoShow(bookingId, reason, notes);
        },
      ),
    );
  }

  Widget _buildStatusTabs() {
    final pendingCount = _bookings
        .where(
          (b) =>
              (b['status'] ?? 'pending').toString().toLowerCase() == 'pending',
        )
        .length;
    final confirmedCount = _bookings
        .where(
          (b) => (b['status'] ?? '').toString().toLowerCase() == 'confirmed',
        )
        .length;
    final arrivedCount = _bookings
        .where((b) => (b['status'] ?? '').toString().toLowerCase() == 'arrived')
        .length;
    final noShowCount = _bookings
        .where((b) => (b['status'] ?? '').toString().toLowerCase() == 'no_show')
        .length;

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        children: [
          _buildStatusTab('pending', 'Pending', pendingCount),
          const SizedBox(width: 10),
          _buildStatusTab('confirmed', 'Confirmed', confirmedCount),
          const SizedBox(width: 10),
          _buildStatusTab('arrived', 'Arrived', arrivedCount),
          const SizedBox(width: 10),
          _buildStatusTab('no_show', 'No-Show', noShowCount),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String status, String label, int count) {
    final isSelected = _selectedStatus == status;
    Color activeBg;
    Color activeText;

    switch (status) {
      case 'confirmed':
        activeBg = AppColors.merchantBlue.withValues(alpha: 0.15);
        activeText = AppColors.merchantBlue;
        break;
      case 'arrived':
        activeBg = AppColors.merchantTeal.withValues(alpha: 0.15);
        activeText = AppColors.merchantTeal;
        break;
      case 'no_show':
        activeBg = AppColors.error.withValues(alpha: 0.15);
        activeText = AppColors.error;
        break;
      default:
        activeBg = AppColors.primaryPurple.withValues(alpha: 0.15);
        activeText = AppColors.primaryPurple;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeText.withValues(alpha: 0.3)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? activeText : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? activeText : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBookings;
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Bookings',
        backgroundColor: Colors.transparent,
        actions: [
          Center(
            child: GestureDetector(
              onTap: () => Get.toNamed(
                AppRoutes.merchantCalendar,
                arguments: {'restaurantId': _selectedRestaurantId},
              ),
              child: _buildCalendarIcon(),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRestaurantFilter(),
          const SizedBox(height: 6),
          if (!_isLoading) _buildStatusTabs(),
          if (!_isLoading && filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Text(
                '${filtered.length} Booking${filtered.length == 1 ? '' : 's'}',
                style: AppTypography.title.copyWith(fontSize: 18),
              ),
            ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : filtered.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadBookings,
                    color: AppColors.merchantBlue,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.sm,
                        AppSpacing.xl,
                        AppSpacing.xxxl,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, index) {
                        return _BookingCard(
                          booking: filtered[index],
                          onReview: _reviewBooking,
                          onArrived: _showArrivedDialog,
                          onNoShow: _showNoShowDialog,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: SkeletonLoader(
          height: 160,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.calendar_today_rounded,
      title: 'No bookings found',
      message: 'Your upcoming reservations will appear here.',
    );
  }

  Widget _buildRestaurantFilter() {
    if (_isLoadingRestaurants && _restaurants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        scrollDirection: Axis.horizontal,
        itemCount: _restaurants.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final restaurant = isAll ? null : _restaurants[index - 1];
          final id = isAll ? null : restaurant!['id'];
          final name = isAll ? 'All Restaurants' : restaurant!['name'];
          final isSelected = _selectedRestaurantId == id;

          return Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRestaurantId = id;
                });
                _loadBookings();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.purpleGradient : null,
                  color: isSelected
                      ? null
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  name,
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarIcon() {
    final dayStr = DateTime.now().day.toString();
    const svgString = '''
<svg viewBox="0 0 497 497" xmlns="http://www.w3.org/2000/svg"><g><g><path d="m16.567 397.6v66.267c0 18.299 14.834 33.133 33.133 33.133h397.6c18.299 0 33.132-14.834 33.132-33.133v-66.267z" fill="#b5dbff"/><path d="m457.433 397.6v66.268c0 18.298-14.834 33.132-33.132 33.132h23c18.299 0 33.132-14.834 33.132-33.132v-66.268z" fill="#97d0ff"/><path d="m16.567 132.533v298.2c0 18.298 14.834 33.132 33.132 33.132h397.601c18.299 0 33.132-14.834 33.132-33.132v-298.2z" fill="#edf5ff"/><path d="m457.433 132.533v298.2c0 18.298-14.834 33.132-33.132 33.132h23c18.299 0 33.132-14.834 33.132-33.132v-298.2z" fill="#d5e8fe"/><path d="m480.433 149.1v-82.834c0-18.299-14.834-33.132-33.132-33.132h-397.601c-18.299 0-33.132 14.834-33.132 33.132v82.834z" fill="#ff435b"/><g><path d="m115.967 73.767h-16.567c-4.142 0-7.5-3.358-7.5-7.5s3.358-7.5 7.5-7.5h16.567c4.142 0 7.5 3.358 7.5 7.5s-3.358 7.5-7.5 7.5z" fill="#e3374e"/></g><g><path d="m165.667 73.767h-16.567c-4.142 0-7.5-3.358-7.5-7.5s3.358-7.5 7.5-7.5h16.566c4.142 0 7.5 3.358 7.5 7.5s-3.357 7.5-7.499 7.5z" fill="#e3374e"/></g><g><path d="m347.9 73.767h-16.566c-4.142 0-7.5-3.358-7.5-7.5s3.358-7.5 7.5-7.5h16.566c4.142 0 7.5 3.358 7.5 7.5s-3.358 7.5-7.5 7.5z" fill="#e3374e"/></g><g><path d="m397.6 73.767h-16.567c-4.142 0-7.5-3.358-7.5-7.5s3.358-7.5 7.5-7.5h16.567c4.142 0 7.5 3.358 7.5 7.5s-3.358 7.5-7.5 7.5z" fill="#e3374e"/></g><path d="m115.967 66.267c0 9.149 7.417 16.567 16.567 16.567s16.567-7.417 16.567-16.567v-49.7c-.001-9.15-7.418-16.567-16.568-16.567-9.149 0-16.567 7.417-16.567 16.567v49.7z" fill="#596c76"/><path d="m347.9 66.267c0 9.149 7.417 16.567 16.567 16.567s16.567-7.417 16.567-16.567v-49.7c0-9.15-7.417-16.567-16.567-16.567s-16.567 7.417-16.567 16.567z" fill="#596c76"/><g fill="#e3374e"><path d="m447.3 33.133h-23c18.299 0 33.132 14.834 33.132 33.132v82.835h23v-82.834c.001-18.299-14.833-33.133-33.132-33.133z"/><path d="m16.567 108.467h463.866v15h-463.866z"/></g></g></g></svg>
''';

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.string(svgString, width: 28, height: 28),
          Padding(
            padding: const EdgeInsets.only(top: 3.5),
            child: Text(
              dayStr,
              style: const TextStyle(
                color: Color(0xFF596C76),
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Function(int, String) onReview;
  final Function(int) onArrived;
  final Function(int) onNoShow;

  const _BookingCard({
    required this.booking,
    required this.onReview,
    required this.onArrived,
    required this.onNoShow,
  });

  void _showBookingDetails(BuildContext context) {
    final restaurant = booking['restaurant_name'] ?? 'Restaurant';
    final customer = booking['contact_name']?.toString().isNotEmpty == true
        ? booking['contact_name']
        : 'Guest';
    final phoneRaw = booking['contact_phone']?.toString().trim() ?? '';
    final phone = phoneRaw.isEmpty ? 'Not provided' : phoneRaw;
    final guests = booking['number_of_guests'] ?? 0;
    final dateStr = booking['booking_date'];
    final status = booking['status'] ?? 'pending';
    final srRaw = booking['special_requests']?.toString().trim() ?? '';
    final specialRequests = srRaw.isEmpty ? 'None' : srRaw;

    DateTime? date;
    if (dateStr != null) {
      date = DateTimeUtils.tryParseBookingInstant(dateStr);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Booking Details',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Customer', value: customer),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Phone',
                value: phone,
                isLink: phone != 'Not provided',
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Restaurant', value: restaurant),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Date & Time',
                value: date != null
                    ? DateTimeUtils.formatDateTime24h(date)
                    : 'N/A',
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Guests', value: guests.toString()),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Status',
                value: _formatBookingStatusForDialog(status),
              ),
              if (status.toLowerCase() == 'arrived' &&
                  booking['arrived_time'] != null) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Arrival Time',
                  value: booking['arrived_time'].toString(),
                ),
              ],
              if (status.toLowerCase() == 'no_show') ...[
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'No-Show Reason',
                  value: booking['no_show_reason'] ?? 'Not specified',
                ),
                if (booking['no_show_notes']?.toString().isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Notes',
                    value: booking['no_show_notes'].toString(),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              _DetailRow(label: 'Special requests', value: specialRequests),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = booking['restaurant_name'] ?? 'Restaurant';
    final customer = booking['contact_name']?.toString().isNotEmpty == true
        ? booking['contact_name']
        : 'Guest';
    final dateStr = booking['booking_date'];
    final guests = booking['number_of_guests'] ?? 0;
    final status = booking['status'] ?? 'pending';

    DateTime? date;
    if (dateStr != null) {
      date = DateTimeUtils.tryParseBookingInstant(dateStr);
    }

    final isPending = status.toLowerCase() == 'pending';
    final isConfirmed = status.toLowerCase() == 'confirmed';
    final initial = customer.toString().substring(0, 1).toUpperCase();

    return GestureDetector(
      onTap: () => _showBookingDetails(context),
      child: AppCard(
        padding: EdgeInsets
            .zero, // Padding handled internally for full-width action bar
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.merchantBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.merchantBlue.withValues(
                              alpha: 0.2,
                            ),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: AppTypography.title.copyWith(
                            color: AppColors.merchantBlue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer,
                              style: AppTypography.title.copyWith(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              restaurant,
                              style: AppTypography.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: date != null
                              ? DateTimeUtils.formatDateTime24h(date)
                              : 'No date',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _InfoChip(
                        icon: Icons.people_outline_rounded,
                        label: '$guests guests',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isPending) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.textDisabled.withValues(alpha: 0.15),
                    ),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24), // Matches AppRadius.card
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final id =
                                  (booking['booking_id'] ?? booking['id']);
                              if (id != null) {
                                onReview(id as int, 'cancelled');
                              }
                            },
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Decline',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: AppColors.textDisabled.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final id =
                                  (booking['booking_id'] ?? booking['id']);
                              if (id != null) {
                                onReview(id as int, 'confirmed');
                              }
                            },
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Confirm',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
            if (isConfirmed) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.textDisabled.withValues(alpha: 0.15),
                    ),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final id =
                                  (booking['booking_id'] ?? booking['id']);
                              if (id != null) {
                                onNoShow(id as int);
                              }
                            },
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off_rounded,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mark No-Show',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: AppColors.textDisabled.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final id =
                                  (booking['booking_id'] ?? booking['id']);
                              if (id != null) {
                                onArrived(id as int);
                              }
                            },
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mark Arrived',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppColors.merchantBlue;
        bg = AppColors.merchantBlue.withValues(alpha: 0.1);
        icon = Icons.check_circle_rounded;
        label = 'Confirmed';
        break;
      case 'arrived':
        color = AppColors.merchantTeal;
        bg = AppColors.merchantTeal.withValues(alpha: 0.1);
        icon = Icons.check_circle_rounded;
        label = 'Arrived';
        break;
      case 'no_show':
        color = AppColors.error;
        bg = AppColors.error.withValues(alpha: 0.1);
        icon = Icons.cancel_rounded;
        label = 'No-Show';
        break;
      case 'cancelled':
        color = AppColors.error;
        bg = AppColors.error.withValues(alpha: 0.1);
        icon = Icons.cancel_rounded;
        label = 'Declined';
        break;
      default:
        color = AppColors.discount;
        bg = AppColors.discount.withValues(alpha: 0.1);
        icon = Icons.hourglass_top_rounded;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLink;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: isLink ? AppColors.merchantBlue : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
