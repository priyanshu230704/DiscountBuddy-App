import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/app_scaffold.dart';
import '../../services/booking_service.dart';
import '../../components/layout.dart';
import '../../components/buttons.dart';

class UserBookingsView extends StatefulWidget {
  const UserBookingsView({super.key});

  @override
  State<UserBookingsView> createState() => _UserBookingsViewState();
}

class _UserBookingsViewState extends State<UserBookingsView> {
  final BookingService _bookingService = BookingService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _bookingService.getUserBookings();
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
    }
  }

  Future<void> _cancelBooking(int id) async {
    try {
      await _bookingService.cancelBooking(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const LoadingWidget(message: 'Loading your bookings...')
        : _bookings.isEmpty
        ? const EmptyStateWidget(
            icon: Icons.event_busy,
            title: 'No bookings found',
            message: 'Your reservations will appear here once you book a table.',
          )
        : RefreshIndicator(
            onRefresh: _loadBookings,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                100,
              ),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return _UserBookingCard(
                  booking: booking,
                  onCancel: () => _cancelBooking(booking['id']),
                );
              },
            ),
          );
  }
}

class _UserBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onCancel;

  const _UserBookingCard({required this.booking, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'pending';
    final isCancellable = status == 'pending' || status == 'confirmed';
    final dateStr = booking['booking_date'];
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    // Determine restaurant name
    String restaurantName = 'Restaurant';
    if (booking['restaurant_name'] != null) {
      restaurantName = booking['restaurant_name'];
    } else if (booking['restaurant'] is Map &&
        booking['restaurant']['name'] != null) {
      restaurantName = booking['restaurant']['name'];
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  restaurantName,
                  style: AppTypography.title.copyWith(fontSize: 18),
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: AppSpacing.sm),
              Text(
                date != null
                    ? DateFormat('MMM d, yyyy HH:mm').format(date.toLocal())
                    : dateStr ?? '',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.people, size: 16, color: Colors.grey),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${booking['number_of_guests']} guests',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          if (isCancellable) ...[
            const Divider(height: 24),
            SecondaryButton(
              label: 'Cancel booking',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cancel booking?'),
                    content: const Text(
                      'Are you sure you want to cancel this reservation?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onCancel();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Yes, cancel'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
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
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppColors.success;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = AppColors.discount;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.caption.copyWith(color: color),
      ),
    );
  }
}
