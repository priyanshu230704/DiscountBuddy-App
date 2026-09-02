import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/services/merchant_service.dart';
import 'package:discount_buddy/utils/date_time_utils.dart';

class MerchantCalendarPage extends StatefulWidget {
  final int? restaurantId;
  const MerchantCalendarPage({super.key, this.restaurantId});

  @override
  State<MerchantCalendarPage> createState() => _MerchantCalendarPageState();
}

class _MerchantCalendarPageState extends State<MerchantCalendarPage> {
  final MerchantService _merchantService = MerchantService();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() => _isLoading = true);
      final bookings = await _merchantService.getMerchantBookings(
        restaurantId: widget.restaurantId,
      );
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper to check if two DateTimes are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Get bookings for a specific day
  List<Map<String, dynamic>> _getBookingsForDay(DateTime date) {
    return _bookings.where((b) {
      final dateStr = b['booking_date'];
      if (dateStr == null) return false;
      final bDate = DateTime.tryParse(dateStr);
      if (bDate == null) return false;
      return _isSameDay(bDate, date);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Calendar',
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.merchantBlue))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  _buildMonthView(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ==================== MONTH VIEW ====================
  Widget _buildMonthView() {
    // Let's draw June 2026 specifically or use the selectedDate month.
    // For convenience of the design mockup, we'll draw the month of selectedDate.
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final monthName = _getMonthName(month);
    
    // First day of the month
    final firstDayOfMonth = DateTime(year, month, 1);
    // Days in month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Weekday of the first day (Monday = 1, Sunday = 7)
    final startWeekday = firstDayOfMonth.weekday; // 1 to 7

    // Calendar grid calculation
    final List<DateTime?> gridDays = [];
    // Pad start of grid
    for (int i = 1; i < startWeekday; i++) {
      gridDays.add(null);
    }
    // Add days
    for (int i = 1; i <= daysInMonth; i++) {
      gridDays.add(DateTime(year, month, i));
    }

    final dayBookings = _getBookingsForDay(_selectedDate);
    final totalGuests = dayBookings.fold<int>(0, (sum, item) => sum + (item['number_of_guests'] as int? ?? 0));
    final estimatedTables = (totalGuests / 4.0).ceil(); // Mock table calculation

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(year, month - 1, 1);
                });
              },
            ),
            Text(
              '$monthName $year',
              style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(year, month + 1, 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Weekday Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((d) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        d,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Days Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: gridDays.length,
          itemBuilder: (context, index) {
            final day = gridDays[index];
            if (day == null) return const SizedBox.shrink();

            final isSelected = _isSameDay(day, _selectedDate);
            final isToday = _isSameDay(day, DateTime.now());
            final bookingsForThisDay = _getBookingsForDay(day);
            final hasBookings = bookingsForThisDay.isNotEmpty;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = day;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryPurple
                      : (isToday ? AppColors.primaryPurple.withValues(alpha: 0.1) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryPurple
                        : (isToday ? AppColors.primaryPurple : AppColors.cardBorder),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.day.toString(),
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isToday ? AppColors.primaryPurple : AppColors.textPrimary),
                        fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    if (hasBookings) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: bookingsForThisDay.take(3).map((b) {
                          Color dotColor;
                          final status = b['status']?.toString().toLowerCase();
                          if (status == 'confirmed') {
                            dotColor = AppColors.merchantBlue;
                          } else if (status == 'arrived') {
                            dotColor = AppColors.merchantTeal;
                          } else if (status == 'no_show') {
                            dotColor = AppColors.error;
                          } else {
                            dotColor = AppColors.merchantAmber;
                          }
                          return Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : dotColor,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        // Day Statistics Summary
        Text(
          'Overview for ${dayBookings.isEmpty ? '${_selectedDate.day} $monthName' : 'Day Stats'}',
          style: AppTypography.title.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.calendar_today_rounded,
                label: 'Bookings',
                value: dayBookings.length.toString(),
                color: AppColors.merchantBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.people_outline_rounded,
                label: 'Guests',
                value: totalGuests.toString(),
                color: AppColors.merchantTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.table_restaurant_rounded,
                label: 'Tables',
                value: dayBookings.isEmpty ? '0' : estimatedTables.toString(),
                color: AppColors.merchantAmber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Bookings for selected day
        if (dayBookings.isNotEmpty) ...[
          Text(
            'Bookings List',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayBookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final b = dayBookings[index];
              return _buildSimpleBookingTile(b);
            },
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Center(
              child: Text(
                'No bookings scheduled for this day.',
                style: AppTypography.bodySmall,
              ),
            ),
          ),
      ],
    );
  }

  // ==================== SUB-WIDGETS & HELPERS ====================
  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBookingTile(Map<String, dynamic> b) {
    final customer = b['contact_name'] ?? 'Guest';
    final guests = b['number_of_guests'] ?? 0;
    final timeStr = _getBookingTime(b['booking_date']);
    final status = (b['status'] ?? 'pending').toString().toLowerCase();

    Color statusColor;
    if (status == 'confirmed') {
      statusColor = AppColors.merchantBlue;
    } else if (status == 'arrived') {
      statusColor = AppColors.merchantTeal;
    } else if (status == 'no_show') {
      statusColor = AppColors.error;
    } else {
      statusColor = AppColors.merchantAmber;
    }

    return GestureDetector(
      onTap: () => _showBookingDetails(context, b),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer,
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$guests Guests • $timeStr',
                  style: AppTypography.caption,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }



  String _getBookingTime(String? dateStr) {
    return DateTimeUtils.formatBookingTimeFromIso(dateStr);
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking) {
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

    final arrivedTimeStr = booking['arrived_time'];

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
                value: DateTimeUtils.formatBookingDateTimeFromIso(dateStr),
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
                  value: DateTimeUtils.formatBookingDateTimeFromIso(
                    arrivedTimeStr,
                  ),
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
}

String _formatBookingStatusForDialog(dynamic raw) {
  final t = (raw ?? 'pending').toString().trim().toLowerCase();
  if (t.isEmpty) return 'Pending';
  return '${t[0].toUpperCase()}${t.substring(1)}';
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
