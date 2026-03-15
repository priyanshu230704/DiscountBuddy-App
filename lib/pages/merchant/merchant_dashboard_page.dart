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
  int _activeDeals = 0;
  double _averageRating = 0.0;
  String _totalViews = "0";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboardData();
    });
  }

  Future<void> _fetchDashboardData() async {
    if (_isFetching) return;

    try {
      setState(() {
        _isLoading = true;
        _isFetching = true;
      });

      // Simulating a brief delay for a premium feel
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        setState(() {
          // Static Demo Data
          _totalBookings = 124;
          _activeDeals = 8;
          _averageRating = 4.8;
          _totalViews = "12.5k";
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
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
      backgroundColor: const Color(0xFFF8F9FE),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildHeader(),
            
            // Business Overview Section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Business Overview',
                      style: AppTypography.headline.copyWith(
                        fontSize: 24, 
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Last 30 days',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textDisabled,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
              sliver: _buildStatsSliver(),
            ),
            
            // Management Tools Section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxxl, AppSpacing.xl, AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Management Tools',
                  style: AppTypography.headline.copyWith(
                    fontSize: 20, 
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            
            _buildManagementGridSliver(),
            
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSliver() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ModernStatCard(
                  label: 'Bookings',
                  value: _totalBookings.toString(),
                  isLoading: _isLoading,
                  icon: Icons.event_available_rounded,
                  color: const Color(0xFF4F46E5),
                  backgroundColor: const Color(0xFFEEF2FF),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ModernStatCard(
                  label: 'Active Deals',
                  value: _activeDeals.toString(),
                  isLoading: _isLoading,
                  icon: Icons.confirmation_number_outlined,
                  color: const Color(0xFF059669),
                  backgroundColor: const Color(0xFFECFDF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ModernStatCard(
                  label: 'Rating',
                  value: _averageRating.toStringAsFixed(1),
                  isLoading: _isLoading,
                  icon: Icons.star_rounded,
                  color: const Color(0xFFD97706),
                  backgroundColor: const Color(0xFFFFFBEB),
                  suffix: ' / 5.0',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ModernStatCard(
                  label: 'Profile Views',
                  value: _totalViews,
                  isLoading: _isLoading,
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFFDB2777),
                  backgroundColor: const Color(0xFFFDF2F8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementGridSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildListDelegate([
          _MenuCard(
            title: 'Bookings',
            subtitle: 'Manage reservations',
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF4F46E5),
            gradient: const [Color(0xFF6366F1), Color(0xFF4338CA)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MerchantBookingsPage(),
              ),
            ).then((_) => _fetchDashboardData()),
          ),
          _MenuCard(
            title: 'Restaurants',
            subtitle: 'Locations & info',
            icon: Icons.storefront_rounded,
            color: const Color(0xFF0EA5E9),
            gradient: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MerchantRestaurantsPage(),
              ),
            ).then((_) => _fetchDashboardData()),
          ),
          _MenuCard(
            title: 'Menu Items',
            subtitle: 'Food & drinks',
            icon: Icons.restaurant_menu_rounded,
            color: const Color(0xFF10B981),
            gradient: const [Color(0xFF34D399), Color(0xFF059669)],
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
            subtitle: 'Promotions & offers',
            icon: Icons.local_offer_rounded,
            color: const Color(0xFFF59E0B),
            gradient: const [Color(0xFFFBBF24), Color(0xFFD97706)],
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
            icon: Icons.star_half_rounded,
            color: const Color(0xFFEC4899),
            gradient: const [Color(0xFFF472B6), Color(0xFFDB2777)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MerchantReviewsPage(),
              ),
            ).then((_) => _fetchDashboardData()),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: const Color(0xFFF8F9FE),
      automaticallyImplyLeading: false,
      expandedHeight: 80,
      collapsedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    "assets/png/db_logo.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Discount Buddy",
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Merchant Central",
                      style: AppTypography.title.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDarkest,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Scanner action button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRScannerPage(),
                      ),
                    ).then((_) => _fetchDashboardData()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scan',
                            style: AppTypography.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _ModernStatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String? suffix;

  const _ModernStatCard({
    required this.label,
    required this.value,
    this.isLoading = false,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.02),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isLoading)
            Container(
              height: 32,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: AppTypography.headline.copyWith(
                    fontSize: 28,
                    color: AppColors.textDarkest,
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      suffix!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
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
  final List<Color> gradient;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.title.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDarkest,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
