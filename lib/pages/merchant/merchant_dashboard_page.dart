import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import 'merchant_restaurants_page.dart';
import 'merchant_deals_page.dart';
import 'merchant_bookings_page.dart';
import 'merchant_reviews_page.dart';
import 'qr_scanner_page.dart';
import '../../services/merchant_service.dart';

/// Merchant Dashboard Page - Central hub for restaurant owners
class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  final MerchantService _merchantService = MerchantService();
  bool _isLoading = true;
  int _totalBookings = 0;
  double _averageRating = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final bookings = await _merchantService.getMerchantBookings();
      final reviews = await _merchantService.getMerchantReviews();

      double totalRating = 0;
      if (reviews.isNotEmpty) {
        for (var review in reviews) {
          totalRating += (review['rating'] as num).toDouble();
        }
      }

      if (mounted) {
        setState(() {
          _totalBookings = bookings.length;
          _averageRating = reviews.isNotEmpty
              ? totalRating / reviews.length
              : 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: NeoTasteColors.accent,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Dashboard',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your restaurants and track performance',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: NeoTasteColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main Actions Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildListDelegate([
                    _DashboardCard(
                      title: 'Restaurants',
                      subtitle: 'Manage profiles',
                      icon: Icons.restaurant,
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantRestaurantsPage(),
                        ),
                      ).then((_) => _fetchDashboardData()),
                    ),
                    _DashboardCard(
                      title: 'Menu',
                      subtitle: 'Manage food items',
                      icon: Icons.menu_book,
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantRestaurantsPage(
                            selectMenuMode: true,
                          ),
                        ),
                      ).then((_) => _fetchDashboardData()),
                    ),
                    _DashboardCard(
                      title: 'Active Deals',
                      subtitle: 'Manage offers',
                      icon: Icons.local_offer,
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantDealsPage(),
                        ),
                      ).then((_) => _fetchDashboardData()),
                    ),
                    _DashboardCard(
                      title: 'Bookings',
                      subtitle: 'View reservations',
                      icon: Icons.event_available,
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantBookingsPage(),
                        ),
                      ).then((_) => _fetchDashboardData()),
                    ),
                    _DashboardCard(
                      title: 'Reviews',
                      subtitle: 'Customer feedback',
                      icon: Icons.rate_review,
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantReviewsPage(),
                        ),
                      ).then((_) => _fetchDashboardData()),
                    ),
                    _DashboardCard(
                      title: 'Redeem',
                      subtitle: 'Scan QR Code',
                      icon: Icons.qr_code_scanner,
                      color: Colors.red,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QRScannerPage(),
                        ),
                      ).then((_) => _fetchDashboardData()),
                    ),
                  ]),
                ),
              ),

              // Quick Stats Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Insights',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: NeoTasteColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: NeoTasteColors.accent,
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _QuickStat(
                                    label: 'Bookings',
                                    value: _totalBookings.toString(),
                                  ),
                                  _QuickStat(
                                    label: 'Avg Rating',
                                    value:
                                        '${_averageRating.toStringAsFixed(1)}★',
                                  ),
                                ],
                              ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Error: $_error',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
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
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: NeoTasteColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: NeoTasteColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: NeoTasteColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;

  const _QuickStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: NeoTasteColors.accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: NeoTasteColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
