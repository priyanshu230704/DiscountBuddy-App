import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../services/merchant_service.dart';
import '../../widgets/skeleton_loader.dart';

class MerchantBookingsPage extends StatefulWidget {
  const MerchantBookingsPage({super.key});

  @override
  State<MerchantBookingsPage> createState() => _MerchantBookingsPageState();
}

class _MerchantBookingsPageState extends State<MerchantBookingsPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _merchantService.getMerchantBookings();
      // Sort by date desc
      bookings.sort((a, b) {
        final dateA = DateTime.tryParse(a['booking_date'] ?? '') ?? DateTime(0);
        final dateB = DateTime.tryParse(b['booking_date'] ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookings: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _reviewBooking(int id, String status) async {
    try {
      await _merchantService.reviewBooking(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking ${status == 'confirmed' ? 'confirmed' : 'rejected'} successfully',
            ),
          ),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.background,
      appBar: AppBar(
        title: Text(
          'Manage Bookings',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: NeoTasteColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _bookings.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  return _BookingCard(
                    booking: booking,
                    onReview: _reviewBooking,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SkeletonLoader(
          height: 100,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: NeoTasteColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            'No bookings yet',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Function(int, String) onReview;

  const _BookingCard({required this.booking, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final restaurant = booking['restaurant_name'] ?? 'Restaurant';
    final customer = booking['contact_name'] ?? 'Guest';
    final dateStr = booking['booking_date'];
    final guests = booking['number_of_guests'] ?? 0;
    final status = booking['status'] ?? 'pending';

    DateTime? date;
    if (dateStr != null) {
      date = DateTime.tryParse(dateStr);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                customer,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$restaurant • $guests guests',
            style: GoogleFonts.inter(color: NeoTasteColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: NeoTasteColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                date != null
                    ? DateFormat('MMM d, yyyy HH:mm').format(date.toLocal())
                    : (dateStr ?? ''),
                style: GoogleFonts.inter(
                  color: NeoTasteColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          if (status.toLowerCase() == 'pending') ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onReview(booking['id'], 'cancelled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onReview(booking['id'], 'confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
