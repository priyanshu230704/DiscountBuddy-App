import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/design/app_spacing.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/components/buttons.dart';
import 'package:discount_buddy/components/layout.dart';
import '../../services/booking_service.dart';

class CreateBookingPage extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const CreateBookingPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _bookingService = BookingService();

  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();

  final _guestsController = TextEditingController(text: '2');
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _requestController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default time: next hour start
    _selectedTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final bookingDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Basic validation for past dates
      if (bookingDateTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot book for a past time')),
        );
        setState(() => _isLoading = false);
        return;
      }

      await _bookingService.createBooking(
        restaurantId: widget.restaurantId,
        bookingDate: bookingDateTime,
        numberOfGuests: int.parse(_guestsController.text),
        specialRequests: _requestController.text.isNotEmpty
            ? _requestController.text
            : null,
        contactName: _nameController.text.isNotEmpty
            ? _nameController.text
            : null,
        contactPhone: _phoneController.text.isNotEmpty
            ? _phoneController.text
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request sent successfully!'),
            backgroundColor: AppColors.primaryPurple,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(titleText: 'Book table'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.restaurantName,
                  style: AppTypography.title.copyWith(fontSize: 22),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Date & Time Selection
                Row(
                  children: [
                    Expanded(
                      child: _DetailSelector(
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: DateFormat('MMM d, yyyy').format(_selectedDate),
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _DetailSelector(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: _selectedTime.format(context),
                        onTap: () => _selectTime(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Guests
                TextFormField(
                  controller: _guestsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Number of guests',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (int.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Contact Info
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Special Requests
                TextFormField(
                  controller: _requestController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Special requests',
                    prefixIcon: Icon(Icons.message_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Submit Button
                PrimaryButton(
                  label: 'Confirm booking',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submitBooking,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSelector extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DetailSelector({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
