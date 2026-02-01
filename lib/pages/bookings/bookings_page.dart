import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import '../../models/restaurant.dart';
import '../restaurant_details_page.dart';

/// Bookings Screen - Simple and clean UI
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  List<_Booking> _bookings = [];
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
    setState(() {
      _isLoading = true;
    });

    // Mock data - in real app, this would come from API
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _bookings = _generateMockBookings();
      _isLoading = false;
    });
  }

  List<_Booking> _generateMockBookings() {
    return [
      _Booking(
        id: '1',
        restaurantName: 'The Gourmet Kitchen',
        restaurantImageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
        date: DateTime.now().add(const Duration(days: 2)),
        time: '19:00',
        guests: 2,
        status: BookingStatus.upcoming,
        restaurant: Restaurant(
          id: '1',
          name: 'The Gourmet Kitchen',
          description: 'Fine dining experience',
          imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
          address: '123 High Street, London',
          latitude: 51.5074,
          longitude: -0.1278,
          cuisine: 'Fine Dining',
          rating: 4.5,
          reviewCount: 234,
          distance: 0.5,
          discount: Discount(
            type: 'percentage',
            percentage: 20,
            description: '20% off',
          ),
        ),
      ),
      _Booking(
        id: '2',
        restaurantName: 'Cafe Delight',
        restaurantImageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
        date: DateTime.now().add(const Duration(days: 5)),
        time: '12:30',
        guests: 4,
        status: BookingStatus.upcoming,
        restaurant: Restaurant(
          id: '2',
          name: 'Cafe Delight',
          description: 'Casual dining',
          imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
          address: '456 Oxford Street, London',
          latitude: 51.5155,
          longitude: -0.1419,
          cuisine: 'Cafe',
          rating: 4.3,
          reviewCount: 189,
          distance: 1.2,
          discount: Discount(
            type: 'percentage',
            percentage: 15,
            description: '15% off',
          ),
        ),
      ),
      _Booking(
        id: '3',
        restaurantName: 'Pizza Express',
        restaurantImageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
        date: DateTime.now().subtract(const Duration(days: 2)),
        time: '18:00',
        guests: 2,
        status: BookingStatus.completed,
        restaurant: Restaurant(
          id: '3',
          name: 'Pizza Express',
          description: 'Italian pizza',
          imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
          address: '789 Regent Street, London',
          latitude: 51.5099,
          longitude: -0.1336,
          cuisine: 'Italian',
          rating: 4.1,
          reviewCount: 456,
          distance: 0.8,
          discount: Discount(
            type: '2for1',
            description: '2 FOR 1',
          ),
        ),
      ),
    ];
  }

  List<_Booking> _getBookingsForTab(int index) {
    switch (index) {
      case 0: // Upcoming
        return _bookings.where((b) => b.status == BookingStatus.upcoming).toList();
      case 1: // Completed
        return _bookings.where((b) => b.status == BookingStatus.completed).toList();
      case 2: // Cancelled
        return _bookings.where((b) => b.status == BookingStatus.cancelled).toList();
      default:
        return _bookings.where((b) => b.status == BookingStatus.upcoming).toList();
    }
  }

  String _getTabLabel(int index) {
    switch (index) {
      case 0:
        return 'Upcoming';
      case 1:
        return 'Completed';
      case 2:
        return 'Cancelled';
      default:
        return 'Upcoming';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.white,
      appBar: AppBar(
        title: Text(
          'Bookings',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: NeoTasteColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tabs (Scrollable)
          Container(
            color: NeoTasteColors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.green,
              unselectedLabelColor: NeoTasteColors.textSecondary,
              indicatorColor: Colors.green,
              indicatorWeight: 2,
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Bookings List (Scrollable content with TabBarView)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadBookings,
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: List.generate(3, (index) {
                      final bookings = _getBookingsForTab(index);
                      final tabLabel = _getTabLabel(index);
                      
                      return bookings.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_note_outlined,
                                    size: 64,
                                    color: NeoTasteColors.textDisabled,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No ${tabLabel.toLowerCase()} bookings',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: NeoTasteColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: bookings.length,
                              itemBuilder: (context, itemIndex) {
                                final booking = bookings[itemIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _BookingCard(booking: booking),
                                );
                              },
                            );
                    }),
                  ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Booking Model
class _Booking {
  final String id;
  final String restaurantName;
  final String restaurantImageUrl;
  final DateTime date;
  final String time;
  final int guests;
  final BookingStatus status;
  final Restaurant restaurant;

  _Booking({
    required this.id,
    required this.restaurantName,
    required this.restaurantImageUrl,
    required this.date,
    required this.time,
    required this.guests,
    required this.status,
    required this.restaurant,
  });
}

enum BookingStatus {
  upcoming,
  completed,
  cancelled,
}

/// Booking Card Widget
class _BookingCard extends StatelessWidget {
  final _Booking booking;

  const _BookingCard({required this.booking});

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getStatusColor() {
    switch (booking.status) {
      case BookingStatus.upcoming:
        return Colors.green;
      case BookingStatus.completed:
        return NeoTasteColors.textSecondary;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (booking.status) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final slug = booking.restaurant.slug ?? booking.restaurant.id;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsPage(slug: slug),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: NeoTasteColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: NeoTasteColors.textDisabled.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Restaurant Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.network(
                booking.restaurantImageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 100,
                  color: NeoTasteColors.textDisabled,
                  child: const Icon(Icons.restaurant),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Name
                    Text(
                      booking.restaurantName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: NeoTasteColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Date and Time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: NeoTasteColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(booking.date),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: NeoTasteColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: NeoTasteColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.time,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: NeoTasteColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Guests
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: NeoTasteColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${booking.guests} ${booking.guests == 1 ? 'guest' : 'guests'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: NeoTasteColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
