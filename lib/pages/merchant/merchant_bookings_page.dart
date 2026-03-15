import 'package:flutter/material.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/design/app_spacing.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:discount_buddy/components/layout.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:intl/intl.dart';
import '../../services/merchant_service.dart';
import '../../widgets/skeleton_loader.dart';

class MerchantBookingsPage extends StatefulWidget {
  const MerchantBookingsPage({super.key});

  @override
  State<MerchantBookingsPage> createState() => _MerchantBookingsPageState();
}

class _MerchantBookingsPageState extends State<MerchantBookingsPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (_isFetching) return;

    try {
      setState(() {
        _isLoading = true;
        _isFetching = true;
      });

      final bookings = await _merchantService.getMerchantBookings();
      // Sort by date desc
      bookings.sort((a, b) {
        final dateA = DateTime.tryParse(a['booking_date'] ?? '') ?? DateTime(0);
        final dateB = DateTime.tryParse(b['booking_date'] ?? '') ?? DateTime(0);
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
          SnackBar(content: Text('Failed to load bookings: ${e.toString()}')),
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
          SnackBar(content: Text('Failed to update: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        titleText: 'Bookings',
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _bookings.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadBookings,
              color: AppColors.accent,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.xl),
                itemCount: _bookings.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  return _BookingCard(
                    booking: booking,
                    onReview: _reviewBooking,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: SkeletonLoader(
          height: 120,
          borderRadius: BorderRadius.circular(16),
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
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Function(int, String) onReview;

  const _BookingCard({required this.booking, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final restaurant = booking['restaurant_name'] ?? 'Restaurant';
    final customer = booking['contact_name'] ?? 'Guest';
    final dateStr = booking['booking_date'];
    final guests = booking['number_of_guests'] ?? 0;
    final status = booking['status'] ?? 'pending';

    DateTime? date;
    if (dateStr != null) {
      date = DateTime.tryParse(dateStr);
    }

    final isPending = status.toLowerCase() == 'pending';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Column(
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
                          customer,
                          style: AppTypography.title,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          restaurant,
                          style: AppTypography.subtitle,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: date != null
                        ? DateFormat('MMM d, h:mm a').format(date.toLocal())
                        : 'No date',
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
          if (isPending) ...[
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.textDisabled.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => onReview(booking['id'], 'cancelled'),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Decline',
                          style: AppTypography.body.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppColors.textDisabled.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => onReview(booking['id'], 'confirmed'),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(14),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Confirm Booking',
                          style: AppTypography.body.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall,
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
        color = const Color(0xFF2E7D32);
        bg = const Color(0xFFE8F5E9);
        icon = Icons.check_circle_outline_rounded;
        label = 'Confirmed';
        break;
      case 'cancelled':
        color = const Color(0xFFC62828);
        bg = const Color(0xFFFFEBEE);
        icon = Icons.cancel_outlined;
        label = 'Cancelled';
        break;
      default:
        color = const Color(0xFFEF6C00);
        bg = const Color(0xFFFFF3E0);
        icon = Icons.hourglass_empty_rounded;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
