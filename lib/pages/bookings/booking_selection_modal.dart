import 'package:discount_buddy/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import 'package:discount_buddy/theme/app_colors.dart';
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
            backgroundColor: AppColors.primaryPurple,
          ),
        );
      }
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
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select your preferred date and time',
                  style: AppFonts.bodyStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Date Selection (Horizontal)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryPurple
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryPurple
                                : AppColors.textDisabled.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(date).toUpperCase(),
                              style: AppFonts.bodyStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primaryPurple
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date.day.toString(),
                              style: AppFonts.bodyStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primaryPurple
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
              const SizedBox(height: 24),

              // Guests Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Guests',
                      style: AppFonts.bodyStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _guestCount > 1
                              ? () => setState(() => _guestCount--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          _guestCount.toString(),
                          style: AppFonts.bodyStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _guestCount++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Time Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Available Times',
                  style: AppFonts.bodyStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (availableTimes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No available times for this day',
                      style: AppFonts.bodyStyle(color: Colors.red),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                ? AppColors.primaryPurple
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryPurple
                                  : AppColors.textDisabled,
                            ),
                          ),
                          child: Text(
                            time,
                            style: AppFonts.bodyStyle(
                              color: isSelected
                                  ? AppColors.surface
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 24),

              // Special Requests
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _requestsController,
                  decoration: InputDecoration(
                    hintText: 'Special requests (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 32),

              // Confirm Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _createBooking,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: _isBooking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Continue to Redemption',
                            style: AppFonts.bodyStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
