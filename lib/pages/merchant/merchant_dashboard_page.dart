import 'package:flutter/material.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/design/app_spacing.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:discount_buddy/design/app_shadows.dart';
import 'package:discount_buddy/design/app_radius.dart';
import 'package:discount_buddy/components/layout.dart';
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
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGradientHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Total Bookings',
                              value: _totalBookings.toString(),
                              isLoading: _isLoading,
                              icon: Icons.calendar_today_rounded,
                              color: AppColors.merchantBlue,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatCard(
                              label: 'Avg Rating',
                              value: _averageRating.toStringAsFixed(1),
                              isLoading: _isLoading,
                              icon: Icons.star_rounded,
                              color: AppColors.merchantAmber,
                              isRating: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      SectionHeader(
                        title: 'Manage Business',
                        subtitle: 'Quick access to your core tools',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.05,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _MenuCard(
                            title: 'Bookings',
                            subtitle: 'View reservations',
                            icon: Icons.event_note_rounded,
                            color: AppColors.merchantBlue,
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
                            color: AppColors.merchantIndigo,
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
                            color: AppColors.merchantTeal,
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
                            color: AppColors.primaryOrange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MerchantDealsPage(),
                              ),
                            ).then((_) => _fetchDashboardData()),
                          ),
                          _MenuCard(
                            title: 'Reviews',
                            subtitle: 'Customer feedback',
                            icon: Icons.rate_review_rounded,
                            color: AppColors.merchantAmber,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MerchantReviewsPage(),
                              ),
                            ).then((_) => _fetchDashboardData()),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.merchantGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: AppTypography.headline.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Track your restaurant progress',
                        style: AppTypography.subtitle.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  _ScanButton(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRScannerPage(),
                      ),
                    ).then((_) => _fetchDashboardData()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Scan',
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
