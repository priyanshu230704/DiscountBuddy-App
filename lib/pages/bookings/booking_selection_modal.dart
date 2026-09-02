import 'package:flutter/material.dart';
import 'package:discount_buddy/utils/date_time_utils.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../design/app_colors.dart';
import '../../design/app_radius.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../components/buttons.dart';
import '../../components/inputs.dart';
import '../../providers/auth_provider.dart';
import '../deals/redeem_offer_modal.dart';
import '../../widgets/generic_bottom_sheet.dart';

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

  /// Bookable times every 30 minutes across all of the day's opening windows.
  ///
  /// A day with a split shift contributes a block per window, so lunch and
  /// dinner times both appear without the gap between them being bookable.
  List<String> _getAvailableTimes() {
    final selectedDayIndex = _selectedDate.weekday - 1;

    final daySlots = widget.restaurant.openingSlots
        .where((slot) => !slot.isClosed && slot.dayIndex == selectedDayIndex)
        .toList();

    if (daySlots.isEmpty) return [];

    daySlots.sort(
      (a, b) => (OpeningHoursFormat.minutesOf(a.openingTime) ?? 0).compareTo(
        OpeningHoursFormat.minutesOf(b.openingTime) ?? 0,
      ),
    );

    final times = <String>[];
    for (final slot in daySlots) {
      final start = OpeningHoursFormat.minutesOf(slot.openingTime);
      final close = OpeningHoursFormat.minutesOf(slot.closingTime);
      if (start == null || close == null) continue;

      // An overnight window runs past midnight, and an all-day window covers
      // the whole day, so both need the end pushed beyond the start.
      final end = close <= start ? close + 24 * 60 : close;

      for (var minutes = start; minutes < end; minutes += 30) {
        final normalized = minutes % (24 * 60);
        final label = DateTimeUtils.formatTimeOfDay24h(
          TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60),
        );
        if (!times.contains(label)) times.add(label);
      }
    }

    if (times.isEmpty) {
      return ['12:00', '13:00', '14:00', '18:00', '19:00', '20:00', '21:00'];
    }

    return times;
  }

  Future<void> _createBooking() async {
    if (!widget.restaurant.bookingsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This restaurant is not accepting bookings at the moment. Please try again later.',
          ),
        ),
      );
      return;
    }

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
      final bookingDateTime = DateTimeUtils.utcInstantFromRestaurantWallClock(
        year: _selectedDate.year,
        month: _selectedDate.month,
        day: _selectedDate.day,
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
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
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
        final raw = e.toString().toLowerCase();
        final message = raw.contains('bookings are not available') ||
                raw.contains('bookings_disabled')
            ? 'This restaurant is not accepting bookings at the moment. Please try again later.'
            : e.toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
