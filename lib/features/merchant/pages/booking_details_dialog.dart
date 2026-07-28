import 'package:flutter/material.dart';
import 'package:discount_buddy/core/theme/app_design.dart';
import 'package:discount_buddy/core/utils/date_time_utils.dart';

String formatBookingStatusForDialog(dynamic raw) {
  final t = (raw ?? 'pending').toString().trim().toLowerCase();
  if (t.isEmpty) return 'Pending';
  return '${t[0].toUpperCase()}${t.substring(1)}';
}

/// Same booking details popup used on merchant bookings / calendar / reminders.
void showMerchantBookingDetailsDialog(
  BuildContext context,
  Map<String, dynamic> booking,
) {
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

  DateTime? date;
  if (dateStr != null) {
    date = DateTimeUtils.tryParseBookingInstant(dateStr);
  }

  DateTime? arrivedDate;
  final arrivedTimeStr = booking['arrived_time'];
  if (arrivedTimeStr != null) {
    arrivedDate = DateTimeUtils.tryParseBookingInstant(arrivedTimeStr);
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
            _DetailRow(label: 'Customer', value: customer.toString()),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Phone',
              value: phone,
              isLink: phone != 'Not provided',
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Restaurant', value: restaurant.toString()),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Date & Time',
              value: date != null
                  ? DateTimeUtils.formatDateTime24h(date)
                  : 'N/A',
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Guests', value: guests.toString()),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Status',
              value: formatBookingStatusForDialog(status),
            ),
            if (status.toString().toLowerCase() == 'arrived' &&
                booking['arrived_time'] != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Arrival Time',
                value: arrivedDate != null
                    ? DateTimeUtils.formatDateTime24h(arrivedDate)
                    : booking['arrived_time'].toString(),
              ),
            ],
            if (status.toString().toLowerCase() == 'no_show') ...[
              const SizedBox(height: 12),
              _DetailRow(
                label: 'No-Show Reason',
                value: booking['no_show_reason'] ?? 'Not specified',
              ),
              if (booking['no_show_notes']?.toString().isNotEmpty == true) ...[
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
