import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discount_buddy/core/utils/date_time_utils.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant.dart';
import 'package:discount_buddy/features/bookings/data/booking_provider.dart';
import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/core/theme/app_radius.dart';
import 'package:discount_buddy/core/theme/app_spacing.dart';
import 'package:discount_buddy/core/theme/app_typography.dart';
import 'package:discount_buddy/components/buttons.dart';
import 'package:discount_buddy/components/inputs.dart';
import 'package:discount_buddy/features/auth/data/auth_provider.dart';
import 'package:discount_buddy/features/deals/pages/redeem_offer_modal.dart';
import 'package:discount_buddy/widgets/generic_bottom_sheet.dart';

class BookingSelectionModal extends StatefulWidget {
  final Restaurant restaurant;

  const BookingSelectionModal({super.key, required this.restaurant});

  @override
  State<BookingSelectionModal> createState() => _BookingSelectionModalState();
}

class _BookingSelectionModalState extends State<BookingSelectionModal> {
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
        times.add(
          DateTimeUtils.formatTimeOfDay24h(
            TimeOfDay(hour: current.hour, minute: current.minute),
          ),
        );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a time')));
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

      final success = await context.read<BookingProvider>().createBooking(
        restaurantId: int.parse(widget.restaurant.id),
        bookingDate: bookingDateTime,
        numberOfGuests: _guestCount,
        specialRequests: _requestsController.text,
        contactName: AuthProvider().user?.email ?? 'Guest',
        contactPhone: '',
      );

      if (!mounted) return;

      if (!success) {
        setState(() => _isBooking = false);
        final failure = context.read<BookingProvider>().failure;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure?.message ?? 'Booking failed')),
        );
        return;
      }

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
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Text(
                  'Select your preferred date and time',
                  style: AppTypography.bodySmall,
                ),
              ),
              SizedBox(height: AppSpacing.xxl),

              // Date Selection (Horizontal)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: AppRadius.medium,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textDisabled.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateTimeUtils.formatShortWeekday(date)
                                  .toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              date.day.toString(),
                              style: AppTypography.title.copyWith(
                                fontSize: 18,
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: AppSpacing.xxl),

              // Guests Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Guests', style: AppTypography.title.copyWith(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _guestCount > 1
                              ? () => setState(() => _guestCount--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.primary,
                        ),
                        Text(
                          _guestCount.toString(),
                          style: AppTypography.title.copyWith(fontSize: 18),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _guestCount++),
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxl),

              // Time Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Text(
                  'Available Times',
                  style: AppTypography.title.copyWith(fontSize: 16),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              if (availableTimes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Center(
                    child: Text(
                      'No available times for this day',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: availableTimes.map((time) {
                      final isSelected = _selectedTime == time;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = time),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: AppRadius.small,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textDisabled,
                            ),
                          ),
                          child: Text(
                            time,
                            style: AppTypography.button.copyWith(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              SizedBox(height: AppSpacing.xxl),

              // Special Requests
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: AppTextField(
                  controller: _requestsController,
                  hintText: 'Special requests (optional)',
                  maxLines: 2,
                ),
              ),
              SizedBox(height: AppSpacing.xxxl),

              // Confirm Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: PrimaryButton(
                  label: 'Continue to Redemption',
                  onPressed: _createBooking,
                  isLoading: _isBooking,
                  expand: true,
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
