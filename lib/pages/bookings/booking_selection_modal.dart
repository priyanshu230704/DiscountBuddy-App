import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../providers/auth_provider.dart';
import '../deals/redeem_offer_modal.dart';
import '../../widgets/generic_bottom_sheet.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class BookingSelectionModal extends StatefulWidget {
  final Restaurant restaurant;

  const BookingSelectionModal({super.key, required this.restaurant});

  @override
  State<BookingSelectionModal> createState() => _BookingSelectionModalState();
}

class _BookingSelectionModalState extends State<BookingSelectionModal> {
  final RestaurantService _restaurantService = RestaurantService();
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  int _guestCount = 2;
  bool _isBooking = false;
  final TextEditingController _requestsController = TextEditingController();

  List<String> _getAvailableTimes() {
    // Current logic: Find slots for the day of the week
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final selectedDayName = dayNames[_selectedDate.weekday - 1];

    final slot = widget.restaurant.openingSlots.firstWhere(
      (s) => s.dayName.toLowerCase() == selectedDayName.toLowerCase(),
      orElse: () => OpeningSlot(
        dayName: '',
        openingTime: '',
        closingTime: '',
        isClosed: true,
      ),
    );

    if (slot.isClosed || slot.openingTime.isEmpty) return [];

    // Generate slots every 30 mins
    final times = <String>[];
    try {
      final start = _parseTime(slot.openingTime);
      final end = _parseTime(slot.closingTime);

      var current = start;
      while (current.isBefore(end)) {
        times.add(DateFormat('HH:mm').format(current));
        current = current.add(const Duration(minutes: 30));
      }
    } catch (e) {
      // Fallback
      return ['12:00', '13:00', '14:00', '18:00', '19:00', '20:00', '21:00'];
    }

    return times;
  }

  DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Future<void> _createBooking() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final timeParts = _selectedTime!.split(':');
      final bookingDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      await _restaurantService.createBooking(
        restaurantId: int.parse(widget.restaurant.id),
        bookingDate: bookingDateTime,
        numberOfGuests: _guestCount,
        specialRequests: _requestsController.text,
        contactName: AuthProvider().user?.email ?? 'Guest',
        contactPhone: '',
      );

      if (mounted) {
        // Success! Now show Redemption modal
        Navigator.pop(context); // Close Booking Modal

        // Show Redeem modal
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => RedeemOfferModal(restaurant: widget.restaurant),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking confirmed! Ready to redeem offer.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
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
    final availableTimes = _getAvailableTimes();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GenericBottomSheet(
        title: 'Make a Booking',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Select your preferred date and time',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Date Selection (Horizontal)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: 14, // Next 14 days
                  itemBuilder: (context, index) {
                    final date = DateTime.now().add(Duration(days: index));
                    final isSelected =
                        _selectedDate.day == date.day &&
                        _selectedDate.month == date.month;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXl,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.dividerDark
                                      : AppColors.dividerLight),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(date).toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date.day.toString(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Guests Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Guests',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _guestCount > 1
                                ? () => setState(() => _guestCount--)
                                : null,
                            icon: Icon(
                              Icons.remove,
                              color: theme.iconTheme.color,
                            ),
                          ),
                          Text(
                            _guestCount.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _guestCount++),
                            icon: Icon(Icons.add, color: theme.iconTheme.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Time Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Available Times',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (availableTimes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No available times for this day',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTimes.map((time) {
                      final isSelected = _selectedTime == time;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = time),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.dividerDark
                                        : AppColors.dividerLight),
                            ),
                          ),
                          child: Text(
                            time,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected ? Colors.white : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),

              // Special Requests
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextField(
                  controller: _requestsController,
                  decoration: InputDecoration(
                    hintText: 'Special requests (optional)',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Confirm Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _createBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                    ),
                    child: _isBooking
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Continue to Redemption',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
