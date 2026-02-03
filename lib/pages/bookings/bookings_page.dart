import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_interactions.dart' as interaction;
import '../../services/restaurant_service.dart';
import '../restaurant_details_page.dart';

/// Bookings Screen - Integrated with real API
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  final RestaurantService _restaurantService = RestaurantService();
  List<interaction.Booking> _bookings = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final bookings = await _restaurantService.getUserBookings();
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load bookings: $e')));
      }
    }
  }

  List<interaction.Booking> _getBookingsByTab(int index) {
    switch (index) {
      case 0: // Upcoming (Pending & Confirmed)
        return _bookings
            .where(
              (b) =>
                  b.status == interaction.BookingStatus.pending ||
                  b.status == interaction.BookingStatus.confirmed,
            )
            .toList();
      case 1: // Completed
        return _bookings
            .where((b) => b.status == interaction.BookingStatus.completed)
            .toList();
      case 2: // Cancelled
        return _bookings
            .where((b) => b.status == interaction.BookingStatus.cancelled)
            .toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.white,
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: NeoTasteColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: NeoTasteColors.textSecondary,
          indicatorColor: Colors.green,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'History'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : TabBarView(
              controller: _tabController,
              children: [
                _BookingList(
                  bookings: _getBookingsByTab(0),
                  onRefresh: _loadBookings,
                  emptyMessage: 'No upcoming bookings',
                ),
                _BookingList(
                  bookings: _getBookingsByTab(1),
                  onRefresh: _loadBookings,
                  emptyMessage: 'No past bookings',
                ),
                _BookingList(
                  bookings: _getBookingsByTab(2),
                  onRefresh: _loadBookings,
                  emptyMessage: 'No cancelled bookings',
                ),
              ],
            ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<interaction.Booking> bookings;
  final Future<void> Function() onRefresh;
  final String emptyMessage;

  const _BookingList({
    required this.bookings,
    required this.onRefresh,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: NeoTasteColors.textDisabled,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: GoogleFonts.inter(
                      color: NeoTasteColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _BookingCard(booking: bookings[index]);
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final interaction.Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoTasteColors.textDisabled.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showBookingDetails(context, booking.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.restaurantName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: NeoTasteColors.textPrimary,
                      ),
                    ),
                  ),
                  _StatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: NeoTasteColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(booking.bookingDate),
                    style: GoogleFonts.inter(
                      color: NeoTasteColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: NeoTasteColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('HH:mm').format(booking.bookingDate),
                    style: GoogleFonts.inter(
                      color: NeoTasteColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: NeoTasteColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.numberOfGuests} Guests',
                    style: GoogleFonts.inter(
                      color: NeoTasteColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (booking.specialRequests.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),
                Text(
                  'Note: ${booking.specialRequests}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: NeoTasteColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, int bookingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingDetailModal(bookingId: bookingId),
    );
  }
}

class _BookingDetailModal extends StatefulWidget {
  final int bookingId;
  const _BookingDetailModal({required this.bookingId});

  @override
  State<_BookingDetailModal> createState() => _BookingDetailModalState();
}

class _BookingDetailModalState extends State<_BookingDetailModal> {
  final RestaurantService _service = RestaurantService();
  interaction.Booking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final detail = await _service.getBookingDetail(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: NeoTasteColors.textDisabled,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _booking!.restaurantName,
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _StatusBadge(status: _booking!.status),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _DetailRow(
                              icon: Icons.calendar_today,
                              label: 'Date',
                              value: DateFormat(
                                'EEEE, MMM d, yyyy',
                              ).format(_booking!.bookingDate),
                            ),
                            const SizedBox(height: 16),
                            _DetailRow(
                              icon: Icons.access_time,
                              label: 'Time',
                              value: DateFormat(
                                'HH:mm',
                              ).format(_booking!.bookingDate),
                            ),
                            const SizedBox(height: 16),
                            _DetailRow(
                              icon: Icons.people_outline,
                              label: 'Number of Guests',
                              value: '${_booking!.numberOfGuests} People',
                            ),
                            if (_booking!.specialRequests.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _DetailRow(
                                icon: Icons.edit_note,
                                label: 'Special Requests',
                                value: _booking!.specialRequests,
                              ),
                            ],
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailsPage(
                                slug: _booking!.restaurantSlug,
                              ),
                            ),
                          );
                        },
                        child: const Text('View Restaurant'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_booking!.canCancel) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _service.cancelBooking(_booking!.id);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Booking cancelled'),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to cancel: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cancel Booking'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: NeoTasteColors.textSecondary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: NeoTasteColors.textDisabled,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: NeoTasteColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final interaction.BookingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case interaction.BookingStatus.confirmed:
        color = Colors.green;
        text = 'Confirmed';
        break;
      case interaction.BookingStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case interaction.BookingStatus.completed:
        color = NeoTasteColors.textSecondary;
        text = 'Completed';
        break;
      case interaction.BookingStatus.pending:
      default:
        color = Colors.orange;
        text = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
