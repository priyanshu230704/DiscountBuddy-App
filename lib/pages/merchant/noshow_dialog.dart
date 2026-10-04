import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:discount_buddy/utils/date_time_utils.dart';

class NoShowDialog extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Function(String reason, String notes) onConfirm;

  const NoShowDialog({
    super.key,
    required this.booking,
    required this.onConfirm,
  });

  @override
  State<NoShowDialog> createState() => _NoShowDialogState();
}

class _NoShowDialogState extends State<NoShowDialog> {
  final TextEditingController _notesController = TextEditingController();
  String _selectedReason = 'Did not show up';

  final List<String> _reasons = [
    'Did not show up',
    'Late cancellation',
    'Duplicate booking',
    'Customer informed they cannot make it',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.booking['contact_name']?.toString().isNotEmpty == true 
        ? widget.booking['contact_name'] 
        : 'Guest';
    final guests = widget.booking['number_of_guests'] ?? 0;
    
    final dateStr = widget.booking['booking_date'];
    final formattedDate =
        DateTimeUtils.formatBookingDateTimeFromIso(dateStr);

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
                    'Mark as No-Show',
                    style: AppTypography.title.copyWith(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Equalizer space for centering
                ],
              ),
              const SizedBox(height: 24),
              // Big Red Warning Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.person_off_rounded,
                  color: AppColors.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Customer & Booking detail
              Text(
                'Mark as No-Show',
                style: AppTypography.title.copyWith(
                  fontSize: 22,
                  color: AppColors.error,
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
              
              // No-Show Reason Dropdown
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No-Show Reason (Optional)',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    isExpanded: true,
                    style: AppTypography.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedReason = newValue;
                        });
                      }
                    },
                    items: _reasons.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Custom Notes Field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add Note (Optional)',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter additional details...',
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
                    borderSide: const BorderSide(color: AppColors.error, width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                ),
                style: AppTypography.body,
              ),
              const SizedBox(height: 28),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(_selectedReason, _notesController.text);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm No-Show',
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
