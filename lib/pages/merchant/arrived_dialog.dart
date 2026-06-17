import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:discount_buddy/utils/date_time_utils.dart';

class ArrivedDialog extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Function(String arrivalTime) onConfirm;

  const ArrivedDialog({
    super.key,
    required this.booking,
    required this.onConfirm,
  });

  @override
  State<ArrivedDialog> createState() => _ArrivedDialogState();
}

class _ArrivedDialogState extends State<ArrivedDialog> {
  late TextEditingController _timeController;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _timeController = TextEditingController(text: _formatTime(_selectedTime));
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.merchantBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _formatTime(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.booking['contact_name']?.toString().isNotEmpty == true 
        ? widget.booking['contact_name'] 
        : 'Guest';
    final guests = widget.booking['number_of_guests'] ?? 0;
    
    DateTime? date;
    final dateStr = widget.booking['booking_date'];
    if (dateStr != null) {
      date = DateTimeUtils.tryParseBookingInstant(dateStr);
    }
    
    final formattedDate = date != null 
        ? DateTimeUtils.formatDateTime24h(date)
        : 'N/A';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: AppColors.textSecondary,
                  ),
                  Text(
                    'Check-in',
                    style: AppTypography.title.copyWith(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Equalizer space for centering
                ],
              ),
              const SizedBox(height: 24),
              // Big Green Check Mark
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Customer & Booking detail
              Text(
                'Mark as Arrived',
                style: AppTypography.title.copyWith(
                  fontSize: 22,
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customer,
                style: AppTypography.title.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$guests Guests • $formattedDate',
                style: AppTypography.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Arrival Time Input
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Arrival Time',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      hintText: 'Enter arrival time',
                      prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.merchantBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    final arrivalDateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );
                    widget.onConfirm(arrivalDateTime.toUtc().toIso8601String());
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm Arrival',
                    style: AppTypography.button.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
