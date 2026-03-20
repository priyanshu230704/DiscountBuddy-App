import 'package:flutter/material.dart';
import '../../services/merchant_service.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../components/layout.dart';
import '../../components/app_app_bar.dart';
import '../../widgets/skeleton_loader.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        titleText: 'Bookings',
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRestaurantFilter(),
          if (!_isLoading && _bookings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
              child: Text(
                '${_bookings.length} Booking${_bookings.length == 1 ? '' : 's'}',
                style: AppTypography.title.copyWith(fontSize: 18),
              ),
            ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _bookings.isEmpty
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
                      itemCount: _bookings.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, index) {
                        return _BookingCard(
                          booking: _bookings[index],
                          onReview: _reviewBooking,
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
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final restaurant = isAll ? null : _restaurants[index - 1];
          final id = isAll ? null : restaurant!['id'];
          final name = isAll ? 'All Restaurants' : restaurant!['name'];
          final isSelected = _selectedRestaurantId == id;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedRestaurantId = id;
              });
              _loadBookings();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Text(
                name,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Function(int, String) onReview;

  const _BookingCard({required this.booking, required this.onReview});

  void _showBookingDetails(BuildContext context) {
    final restaurant = booking['restaurant_name'] ?? 'Restaurant';
    final customer = booking['contact_name']?.toString().isNotEmpty == true 
        ? booking['contact_name'] 
        : 'Guest';
    final phone = booking['contact_phone'] ?? 'No phone provided';
    final email = booking['contact_email'] ?? 'No email provided';
    final guests = booking['number_of_guests'] ?? 0;
    final dateStr = booking['booking_date'];
    final status = booking['status'] ?? 'pending';
    final specialRequests = booking['special_requests'] ?? 'None';

    DateTime? date;
    if (dateStr != null) {
      date = DateTime.tryParse(dateStr);
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
              _DetailRow(label: 'Phone', value: phone, isLink: true),
              const SizedBox(height: 12),
              _DetailRow(label: 'Email', value: email),
              const SizedBox(height: 12),
              _DetailRow(label: 'Restaurant', value: restaurant),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Date & Time',
                value: date != null ? DateFormat('MMM d, yyyy - h:mm a').format(date.toLocal()) : 'N/A',
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Guests', value: guests.toString()),
              const SizedBox(height: 12),
              _DetailRow(label: 'Status', value: status.toUpperCase()),
              const SizedBox(height: 12),
              const Text('Special Requests:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                specialRequests,
                style: AppTypography.bodySmall,
              ),
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
      date = DateTime.tryParse(dateStr);
    }

    final isPending = status.toLowerCase() == 'pending';
    final initial = customer.toString().substring(0, 1).toUpperCase();

    return GestureDetector(
      onTap: () => _showBookingDetails(context),
      child: AppCard(
      padding: EdgeInsets.zero, // Padding handled internally for full-width action bar
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
                          color: AppColors.merchantBlue.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: AppTypography.title.copyWith(
                          color: AppColors.merchantBlue,
                          fontSize: 18,
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
                            style: AppTypography.title.copyWith(fontSize: 17),
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
                            ? DateFormat('MMM d, h:mm a').format(date.toLocal())
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
                          onTap: () => onReview(booking['id'], 'cancelled'),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close_rounded, size: 18, color: AppColors.error),
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
                          onTap: () => onReview(booking['id'], 'confirmed'),
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 18, color: AppColors.success),
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
        color: AppColors.surface,
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
        color = const Color(0xFF2E7D32);
        bg = const Color(0xFFE8F5E9);
        icon = Icons.check_circle_rounded;
        label = 'Confirmed';
        break;
      case 'cancelled':
        color = const Color(0xFFC62828);
        bg = const Color(0xFFFFEBEE);
        icon = Icons.cancel_rounded;
        label = 'Declined';
        break;
      default:
        color = const Color(0xFFED8936);
        bg = const Color(0xFFFEEBC8);
        icon = Icons.hourglass_top_rounded;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
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
              fontSize: 11,
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

  const _DetailRow({required this.label, required this.value, this.isLink = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
