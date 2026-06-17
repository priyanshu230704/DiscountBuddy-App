import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/services/merchant_service.dart';

class MerchantCalendarPage extends StatefulWidget {
  final int? restaurantId;
  const MerchantCalendarPage({super.key, this.restaurantId});

  @override
  State<MerchantCalendarPage> createState() => _MerchantCalendarPageState();
}

class _MerchantCalendarPageState extends State<MerchantCalendarPage> {
  final MerchantService _merchantService = MerchantService();
  String _selectedTab = 'Month'; // 'Day', 'Week', 'Month'
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
          : Column(
              children: [
                _buildViewToggle(),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      children: [
                        if (_selectedTab == 'Month') _buildMonthView(),
                        if (_selectedTab == 'Week') _buildWeekView(),
                        if (_selectedTab == 'Day') _buildDayView(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _buildToggleItem('Day'),
          _buildToggleItem('Week'),
          _buildToggleItem('Month'),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String tab) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tab;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.purpleGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              tab,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
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

  // ==================== WEEK VIEW ====================
  Widget _buildWeekView() {
    // Find the start of the week (Monday)
    final int weekday = _selectedDate.weekday;
    final DateTime startOfWeek = _selectedDate.subtract(Duration(days: weekday - 1));
    final List<DateTime> weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                });
              },
            ),
            Text(
              'Week of ${_getMonthName(startOfWeek.month)} ${startOfWeek.day}',
              style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 7));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Week Days List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final day = weekDays[index];
            final bookings = _getBookingsForDay(day);
            final isSelected = _isSameDay(day, _selectedDate);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = day;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purple.withValues(alpha: 0.03) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryPurple : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date indicator column
                    Container(
                      width: 45,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryPurple : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getWeekdayShort(day.weekday),
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Bookings lists
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${bookings.length} Reservation${bookings.length == 1 ? '' : 's'}',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: bookings.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                          if (bookings.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Column(
                              children: bookings.take(2).map((b) {
                                final timeStr = _getBookingTime(b['booking_date']);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        timeStr,
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.merchantBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${b['contact_name']} (${b['number_of_guests']} Guests)',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            if (bookings.length > 2)
                              Text(
                                '+ ${bookings.length - 2} more',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==================== DAY VIEW ====================
  Widget _buildDayView() {
    final dayBookings = _getBookingsForDay(_selectedDate);

    // Sort bookings by time
    dayBookings.sort((a, b) {
      final tA = DateTime.tryParse(a['booking_date'] ?? '') ?? DateTime(0);
      final tB = DateTime.tryParse(b['booking_date'] ?? '') ?? DateTime(0);
      return tA.compareTo(tB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                });
              },
            ),
            Text(
              '${_getWeekdayName(_selectedDate.weekday)}, ${_selectedDate.day} ${_getMonthName(_selectedDate.month)}',
              style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Day Timeline
        if (dayBookings.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayBookings.length,
            itemBuilder: (context, index) {
              final b = dayBookings[index];
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

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Time indicator
                      SizedBox(
                        width: 75,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeStr,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Timeline vertical bar
                      Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Booking Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b['contact_name'] ?? 'Guest',
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.group_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${b['number_of_guests']} guests',
                                    style: AppTypography.caption,
                                  ),
                                  if (b['restaurant_name'] != null) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.storefront_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        b['restaurant_name'].toString(),
                                        style: AppTypography.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textDisabled),
                const SizedBox(height: 12),
                Text(
                  'No Bookings Today',
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enjoy the quiet day or select another date.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
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

    return Container(
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
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getWeekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getWeekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _getBookingTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
