import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:discount_buddy/core/theme/app_design.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/features/merchant/data/merchant_service.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'dart:async';
import 'package:discount_buddy/features/notifications/data/notification_provider.dart';

/// Merchant Dashboard Page - Central hub for restaurant owners
class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isFetching = false;
  int _totalBookings = 0;
  int _activeDeals = 0;
  double _averageRating = 0.0;
  double _totalEarnings = 0.0;
  int _totalRedeemedCount = 0;
  int? _primaryRestaurantId;
  String? _currentOccupancy;
  String? _currentAddress;
  // Removed local _notificationCount and subscription as it's handled by NotificationProvider
  final NotificationProvider _notificationProvider = NotificationProvider();

  // Multi-restaurant support

  List<Map<String, dynamic>> _restaurants = [];
  int? _selectedRestaurantId; // null means 'All'
  String _selectedRestaurantName = 'All Restaurants';

  final MerchantService _merchantService = MerchantService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Defer: fetchUnreadCount() notifies listeners; cannot run during build.
      _notificationProvider.fetchUnreadCount(true);
      _fetchDashboardData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sync unread notification count (captures background updates)
      _notificationProvider.fetchUnreadCount(true);
    }
  }

  // Removed local _loadNotificationCount as it's now in NotificationProvider

  Future<void> _fetchDashboardData() async {
    if (_isFetching) return;

    try {
      setState(() {
        _isLoading = true;
        _isFetching = true;
      });

      // Simulating a brief delay for a premium feel
      await Future.delayed(const Duration(milliseconds: 600));

      final stats = await _merchantService.getMerchantDashboardStats(
        restaurantId: _selectedRestaurantId,
      );

      if (mounted) {
        setState(() {
          _totalBookings = stats['total_bookings'] ?? 0;
          _activeDeals = stats['active_deals'] ?? 0;
          _averageRating = (stats['average_rating'] ?? 0.0).toDouble();

          _totalRedeemedCount = stats['total_redeemed'] ?? 0;
          _totalEarnings = (stats['total_earnings'] ?? 0.0).toDouble();

          // Update restaurant list and default selection if needed
          if (stats['restaurants'] != null) {
            _restaurants = List<Map<String, dynamic>>.from(
              stats['restaurants'],
            );

            // If only one restaurant, auto-select it if nothing selected
            if (_restaurants.length == 1 && _selectedRestaurantId == null) {
              _selectedRestaurantId = _restaurants[0]['id'];
              _selectedRestaurantName = _restaurants[0]['name'];
            }
          }

          _primaryRestaurantId = stats['primary_restaurant_id'];
          _currentOccupancy = stats['primary_restaurant_occupancy'];
          _currentAddress = stats['primary_restaurant_address'];

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

  void _onRestaurantSelected(int? id, String name) {
    if (_selectedRestaurantId == id) return;

    setState(() {
      _selectedRestaurantId = id;
      _selectedRestaurantName = name;
    });
    _fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildHeader(),

            // Manager Reminders Banner
            SliverToBoxAdapter(child: _buildRemindersBanner()),

            if (_restaurants.length > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Row(
                      children: [
                        _buildRestaurantChip(null, 'All Restaurants'),
                        ..._restaurants.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _buildRestaurantChip(r['id'], r['name']),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Premium Restaurant Profile & Status
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _buildRestaurantProfile()),
            ),

            // Statistics Section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                0,
              ),
              sliver: _buildStatsSliver(),
            ),

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
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: _ModernStatCard(
                    label: 'Deals Redeemed',
                    value: _totalRedeemedCount.toString(),
                    isLoading: _isLoading,
                    icon: Icons.confirmation_number_rounded,
                    color: const Color(0xFF8B5CF6), // Violet
                    backgroundColor: const Color(0xFFF5F3FF),
                    onTap: () async {
                      await Get.toNamed(
                        AppRoutes.merchantRedemptionHistory,
                        arguments: {'restaurantId': _selectedRestaurantId},
                      );
                      _fetchDashboardData();
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: _ModernStatCard(
                    label: 'Active Deals',
                    value: _activeDeals.toString(),
                    isLoading: _isLoading,
                    icon: Icons.local_offer_rounded,
                    color: const Color(0xFFF59E0B), // Amber
                    backgroundColor: const Color(0xFFFEF3C7),
                    onTap: () async {
                      await Get.toNamed(
                        AppRoutes.merchantDeals,
                        arguments: {'restaurantId': _selectedRestaurantId},
                      );
                      _fetchDashboardData();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: _ModernStatCard(
                    label: 'Bookings',
                    value: _totalBookings.toString(),
                    isLoading: _isLoading,
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFF6366F1), // Indigo
                    backgroundColor: const Color(0xFFEEF2FF),
                    onTap: () async {
                      await Get.toNamed(
                        AppRoutes.merchantBookings,
                        arguments: {'restaurantId': _selectedRestaurantId},
                      );
                      _fetchDashboardData();
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: _ModernStatCard(
                    label: 'Rating',
                    value: _averageRating.toStringAsFixed(1),
                    isLoading: _isLoading,
                    icon: Icons.star_half_rounded,
                    color: const Color(0xFFFACC15), // Yellow
                    backgroundColor: const Color(0xFFFEF9C3),
                    suffix: ' / 5.0',
                    onTap: () async {
                      await Get.toNamed(
                        AppRoutes.merchantReviews,
                        arguments: {'restaurantId': _selectedRestaurantId},
                      );
                      _fetchDashboardData();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: _ModernStatCard(
                    label: 'View Analytics',
                    value: 'Insights',
                    isLoading: _isLoading,
                    icon: Icons.analytics_rounded,
                    color: const Color(0xFF10B981), // Emerald
                    backgroundColor: const Color(0xFFECFDF5),
                    onTap: () => Get.toNamed(
                      AppRoutes.merchantAnalytics,
                      arguments: {
                        'restaurantId': _selectedRestaurantId,
                        'restaurantName': _selectedRestaurantName,
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: _ModernStatCard(
                    label: 'Loyalty Program',
                    value: 'Customers',
                    isLoading: _isLoading,
                    icon: Icons.card_membership_rounded,
                    color: const Color(0xFFEC4899), // Pink
                    backgroundColor: const Color(0xFFFDF2F8),
                    onTap: () async {
                      await Get.toNamed(
                        AppRoutes.merchantLoyalty,
                        arguments: {'restaurantId': _selectedRestaurantId},
                      );
                      _fetchDashboardData();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Slate 100
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _OccupancySegment(
            label: 'Less Busy',
            value: 'available',
            selectedValue: _currentOccupancy,
            onSelected: (val) => _updateOccupancy(val),
            activeColor: const Color(0xFF10B981), // Green 500
          ),
          _OccupancySegment(
            label: 'Moderate',
            value: 'moderately_busy',
            selectedValue: _currentOccupancy,
            onSelected: (val) => _updateOccupancy(val),
            activeColor: const Color(0xFFF59E0B), // Amber 500
          ),
          _OccupancySegment(
            label: 'Busy',
            value: 'very_busy',
            selectedValue: _currentOccupancy,
            onSelected: (val) => _updateOccupancy(val),
            activeColor: const Color(0xFFEF4444), // Red 500
          ),
        ],
      ),
    );
  }

  Future<void> _updateOccupancy(String newOccupancy) async {
    final targetId = _selectedRestaurantId ?? _primaryRestaurantId;
    if (targetId == null || _currentOccupancy == newOccupancy) return;

    final oldOccupancy = _currentOccupancy;
    setState(() => _currentOccupancy = newOccupancy);

    try {
      await _merchantService.updateOccupancy(targetId, newOccupancy);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status updated to ${newOccupancy == 'available' ? 'Less Busy' : newOccupancy.replaceAll('_', ' ')}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.merchantIndigo,
          ),
        );
      }
    } catch (e) {
      setState(() => _currentOccupancy = oldOccupancy);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: const Color(0xFFF3E8FF),
      automaticallyImplyLeading: false,
      expandedHeight: 0,
      toolbarHeight: 74,
      title: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo Avatar with Soft Glow
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset("assets/png/db_logo.png", fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            // Title Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Discount\nBuddy",
                    style: AppTypography.title.copyWith(
                      fontSize: 18,
                      color: AppColors.textDarkest,
                      height: 1.1,
                    ),
                    maxLines: 2,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Live Dashboard",
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Notification Icon
            GestureDetector(
              onTap: () async {
                await Get.toNamed(AppRoutes.notifications);
                _notificationProvider.refreshCount(true);
              },
              child: ListenableBuilder(
                listenable: _notificationProvider,
                builder: (context, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.04),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_none,
                          size: 21,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_notificationProvider.unreadCount > 0)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                _notificationProvider.unreadCount > 99
                                    ? '99+'
                                    : '${_notificationProvider.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            // Calendar Button
            GestureDetector(
              onTap: () => Get.toNamed(
                AppRoutes.merchantCalendar,
                arguments: {'restaurantId': _selectedRestaurantId},
              ),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.04),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 21,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Scanner Button - Refined Design
            GestureDetector(
              onTap: () async {
                await Get.toNamed(
                  AppRoutes.qrScanner,
                  arguments: {'initialRestaurantId': _selectedRestaurantId},
                );
                _fetchDashboardData();
              },
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.04),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 21,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantProfile() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x1A7C3AED), Color(0x1A6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Color(0xFF7C3AED),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedRestaurantName,
                      style: AppTypography.title.copyWith(
                        fontSize: 22,
                        color: AppColors.textDarkest,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _selectedRestaurantId == null
                          ? (_restaurants.length > 1
                                ? "${_restaurants.length} Registered Locations"
                                : "Verified Merchant Partner")
                          : (_currentAddress ?? "Verified Merchant Partner"),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_primaryRestaurantId != null) ...[
            const SizedBox(height: AppSpacing.xl),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "Current Status",
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textDarkest.withValues(alpha: 0.6),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildOccupancyToggle(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _ModernStatCard(
            label: 'Total Earnings',
            value: '£${_totalEarnings.toStringAsFixed(2)}',
            isLoading: _isLoading,
            icon: Icons.payments_rounded,
            color: const Color(0xFF10B981), // Merchant Green
            valueColor: const Color(0xFF10B981),
            backgroundColor: const Color(0xFFECFDF5),
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersBanner() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.merchantReminders),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xs, // small top margin
          AppSpacing.xl,
          0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // compact padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // matching border radius for compact card
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7), // compact icon container
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFF6366F1),
                size: 16, // smaller icon
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manager Reminders',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Upcoming countdown alerts for bookings.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF6366F1),
              size: 20, // smaller chevron
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantChip(int? id, String name) {
    final isSelected = _selectedRestaurantId == id;
    return GestureDetector(
      onTap: () => _onRestaurantSelected(id, name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.purpleGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          name,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

}

class _OccupancySegment extends StatelessWidget {
  final String label;
  final String value;
  final String? selectedValue;
  final Function(String) onSelected;
  final Color activeColor;

  const _OccupancySegment({
    required this.label,
    required this.value,
    this.selectedValue,
    required this.onSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected
                    ? activeColor
                    : const Color(0xFF64748B), // Slate 500
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
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
  final Color? valueColor;
  final Color backgroundColor;
  final String? suffix;
  final bool isFullWidth;
  final VoidCallback? onTap;

  const _ModernStatCard({
    required this.label,
    required this.value,
    required this.isLoading,
    required this.icon,
    required this.color,
    this.valueColor,
    required this.backgroundColor,
    this.suffix,
    this.isFullWidth = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isFullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: isFullWidth ? AppSpacing.md : AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: AppColors.cardBorder.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        child: isFullWidth
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLoading)
                          Container(
                            height: 24,
                            width: 60,
                            decoration: BoxDecoration(
                              color: AppColors.divider.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  value,
                                  style: AppTypography.headline.copyWith(
                                    fontSize: (double.tryParse(value) == null) ? 18 : 22,
                                    color: valueColor ?? AppColors.textDarkest,
                                    letterSpacing: (double.tryParse(value) == null) ? -0.2 : -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (suffix != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    suffix!,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.textDisabled.withValues(alpha: 0.5),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isLoading)
                    Container(
                      height: 20,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.divider.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            style: AppTypography.headline.copyWith(
                              fontSize: (double.tryParse(value) == null) ? 15 : 18,
                              color: valueColor ?? AppColors.textDarkest,
                              letterSpacing: (double.tryParse(value) == null) ? -0.2 : -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (suffix != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Text(
                              suffix!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}
