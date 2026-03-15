import 'package:flutter/material.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/design/app_spacing.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:discount_buddy/components/layout.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
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
  bool _isFetching = false;
  int _totalBookings = 0;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (_isFetching) return;

    try {
      setState(() {
        _isLoading = true;
        _isFetching = true;
      });

      // Run requests in parallel for better performance and deduplication
      final results = await Future.wait([
        _merchantService.getMerchantBookings(),
        _merchantService.getMerchantReviews(),
      ]);

      final bookings = results[0];
      final reviews = results[1];

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
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        _isFetching = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(titleText: 'Dashboard'),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: AppSpacing.screenPadding.copyWith(
              bottom: AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track your restaurant and its real-time progress',
                  style: AppTypography.subtitle,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _ScanActionCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QRScannerPage(),
                    ),
                  ).then((_) => _fetchDashboardData()),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Total Bookings',
                        value: _totalBookings.toString(),
                        isLoading: _isLoading,
                        icon: Icons.calendar_today_rounded,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: StatCard(
                        label: 'Average Rating',
                        value: _averageRating.toStringAsFixed(1),
                        isLoading: _isLoading,
                        icon: Icons.star_rounded,
                        color: AppColors.discount,
                        isRating: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                SectionHeader(
                  title: 'Manage Business',
                  subtitle: 'Quick access to your core merchant tools',
                ),
                const SizedBox(height: AppSpacing.lg),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.lg,
                  crossAxisSpacing: AppSpacing.lg,
                  childAspectRatio: 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MenuCard(
                      title: 'Bookings',
                      subtitle: 'View reservations',
                      icon: Icons.event_note_rounded,
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantBookingsPage(),
                        ),
                      ).then((_) => _fetchDashboardData()),
                    ),
                    _MenuCard(
                      title: 'Restaurants',
                      subtitle: 'Edit details',
                      icon: Icons.storefront_rounded,
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantRestaurantsPage(),
                        ),
                      ).then((_) => _fetchDashboardData()),
                    ),
                    _MenuCard(
                      title: 'Menu Items',
                      subtitle: 'Update food',
                      icon: Icons.restaurant_menu_rounded,
                      color: AppColors.discount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantRestaurantsPage(
                            selectMenuMode: true,
                          ),
                        ),
                      ).then((_) => _fetchDashboardData()),
                    ),
                    _MenuCard(
                      title: 'Active Deals',
                      subtitle: 'Promotions',
                      icon: Icons.local_offer_rounded,
                      color: Colors.red,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantDealsPage(),
                        ),
                      ).then((_) => _fetchDashboardData()),
                    ),
                    _MenuCard(
                      title: 'Reviews',
                      subtitle: 'Feedback',
                      icon: Icons.rate_review_rounded,
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantReviewsPage(),
                        ),
                      ).then((_) => _fetchDashboardData()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanActionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanActionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan redemption',
                  style: AppTypography.title,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Process customer QR codes at the door',
                  style: AppTypography.subtitle,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;
  final IconData icon;
  final Color color;
  final bool isRating;

  const _StatCard({
    required this.label,
    required this.value,
    required this.isLoading,
    required this.icon,
    required this.color,
    this.isRating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Row(
              children: [
                Text(
                  value,
                  style: AppTypography.headline.copyWith(
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
                if (isRating) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                ],
              ],
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
