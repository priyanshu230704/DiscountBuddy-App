import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_interactions.dart' as interaction;
import '../../services/restaurant_service.dart';
import '../restaurant_details_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Bookings Screen - Integrated with real API
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  final RestaurantService _restaurantService = RestaurantService();
  List<interaction.Booking> _bookings = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final bookings = await _restaurantService.getUserBookings();
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<interaction.Booking> _getBookingsByTab(int index) {
    switch (index) {
      case 0: // Upcoming (Pending & Confirmed)
        return _bookings
            .where(
              (b) =>
                  b.status == interaction.BookingStatus.pending ||
                  b.status == interaction.BookingStatus.confirmed,
            )
            .toList();
      case 1: // Completed
        return _bookings
            .where((b) => b.status == interaction.BookingStatus.completed)
            .toList();
      case 2: // Cancelled
        return _bookings
            .where((b) => b.status == interaction.BookingStatus.cancelled)
            .toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'History'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _BookingList(
                  bookings: _getBookingsByTab(0),
                  onRefresh: _loadBookings,
                  emptyMessage: 'No upcoming bookings',
                ),
                _BookingList(
                  bookings: _getBookingsByTab(1),
                  onRefresh: _loadBookings,
                  emptyMessage: 'No past bookings',
                ),
                _BookingList(
                  bookings: _getBookingsByTab(2),
                  onRefresh: _loadBookings,
                  emptyMessage: 'No cancelled bookings',
                ),
              ],
            ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<interaction.Booking> bookings;
  final Future<void> Function() onRefresh;
  final String emptyMessage;

  const _BookingList({
    required this.bookings,
    required this.onRefresh,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: isDark
                        ? AppColors.textSecondaryDark.withOpacity(0.5)
                        : AppColors.textSecondaryLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _BookingCard(booking: bookings[index]);
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final interaction.Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showBookingDetails(context, booking.id),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.restaurantName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(booking.bookingDate),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('HH:mm').format(booking.bookingDate),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.numberOfGuests} Guests',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              if (booking.specialRequests.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: 4),
                Text(
                  'Note: ${booking.specialRequests}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, int bookingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingDetailModal(bookingId: bookingId),
    );
  }
}

class _BookingDetailModal extends StatefulWidget {
  final int bookingId;
  const _BookingDetailModal({required this.bookingId});

  @override
  State<_BookingDetailModal> createState() => _BookingDetailModalState();
}

class _BookingDetailModalState extends State<_BookingDetailModal> {
  final RestaurantService _service = RestaurantService();
  interaction.Booking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final detail = await _service.getBookingDetail(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXxl),
          topRight: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: _isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _booking!.restaurantName,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _StatusBadge(status: _booking!.status),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            _DetailRow(
                              icon: Icons.calendar_today,
                              label: 'Date',
                              value: DateFormat(
                                'EEEE, MMM d, yyyy',
                              ).format(_booking!.bookingDate),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _DetailRow(
                              icon: Icons.access_time,
                              label: 'Time',
                              value: DateFormat(
                                'HH:mm',
                              ).format(_booking!.bookingDate),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _DetailRow(
                              icon: Icons.people_outline,
                              label: 'Number of Guests',
                              value: '${_booking!.numberOfGuests} People',
                            ),
                            if (_booking!.specialRequests.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.lg),
                              _DetailRow(
                                icon: Icons.edit_note,
                                label: 'Special Requests',
                                value: _booking!.specialRequests,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailsPage(
                                slug: _booking!.restaurantSlug,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? AppColors.dividerDark
                                : AppColors.dividerLight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: theme.textTheme.bodyMedium?.color,
                        ),
                        child: const Text('View Restaurant'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_booking!.canCancel) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _service.cancelBooking(_booking!.id);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Booking cancelled'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to cancel: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel Booking'),
                        ),
                      ),
                    ],
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

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark.withOpacity(0.7)
                      : AppColors.textSecondaryLight.withOpacity(0.7),
                ),
              ),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final interaction.BookingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case interaction.BookingStatus.confirmed:
        color = AppColors.success;
        text = 'Confirmed';
        break;
      case interaction.BookingStatus.cancelled:
        color = AppColors.error;
        text = 'Cancelled';
        break;
      case interaction.BookingStatus.completed:
        color = Colors.grey;
        text = 'Completed';
        break;
      case interaction.BookingStatus.pending:
      default:
        color = AppColors.warning;
        text = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
