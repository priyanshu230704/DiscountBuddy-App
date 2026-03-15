import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/design/app_spacing.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/components/layout.dart';
import 'package:discount_buddy/components/buttons.dart';
import '../../models/deal_redemption.dart';
import '../../services/restaurant_service.dart';
import '../restaurant_details_page.dart';

/// Bookings/Redemptions Screen - Integrated with deal uses API
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  final RestaurantService _restaurantService = RestaurantService();
  List<DealRedemption> _redemptions = [];
  bool _isLoading = true;
  late TabController _tabController;
  final List<_TrendingCardData> _trendingItems = const [
    _TrendingCardData(
      name: "Meghwin's Cafe",
      rating: 4.8,
      reviews: 260,
      distanceKm: 0.5,
      code: 'BUDDY30',
      discountLabel: '30% OFF',
      imageUrl:
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?q=80&w=1200&auto=format&fit=crop',
    ),
    _TrendingCardData(
      name: "Spice Hub",
      rating: 4.6,
      reviews: 320,
      distanceKm: 0.8,
      code: 'BUDDY50',
      discountLabel: '50% OFF',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1200&auto=format&fit=crop',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRedemptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRedemptions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final redemptions = await _restaurantService.getUserDealRedemptions();
      if (mounted) {
        setState(() {
          _redemptions = redemptions;
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
        ).showSnackBar(SnackBar(content: Text('Failed to load history: $e')));
      }
    }
  }

  List<DealRedemption> _getRedemptionsByTab(int index) {
    // Sort by date descending
    final sortedList = List<DealRedemption>.from(_redemptions)
      ..sort((a, b) => b.usedAt.compareTo(a.usedAt));

    switch (index) {
      case 1: // Active Coupons
        return sortedList.where((r) => !r.restaurantConfirmed).toList();
      case 2: // Coupons (all)
        return sortedList;
      case 3: // Coupon History
        return sortedList.where((r) => r.restaurantConfirmed).toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(titleText: 'My activity', centerTitle: false),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.only(top: 2),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(text: 'Reservations'),
              Tab(text: 'Active coupons'),
              Tab(text: 'Coupons'),
              Tab(text: 'Coupon history'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading your activity...')
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _ReservationEmptyTab(
                        trendingItems: _trendingItems,
                        onExplorePressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                      ),
                      _RedemptionList(
                        redemptions: _getRedemptionsByTab(1),
                        onRefresh: _loadRedemptions,
                        emptyMessage: 'No active coupons',
                      ),
                      _RedemptionList(
                        redemptions: _getRedemptionsByTab(2),
                        onRefresh: _loadRedemptions,
                        emptyMessage: 'No coupons yet',
                      ),
                      _RedemptionList(
                        redemptions: _getRedemptionsByTab(3),
                        onRefresh: _loadRedemptions,
                        emptyMessage: 'No coupon history',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReservationEmptyTab extends StatelessWidget {
  const _ReservationEmptyTab({
    required this.trendingItems,
    required this.onExplorePressed,
  });

  final List<_TrendingCardData> trendingItems;
  final VoidCallback onExplorePressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No reservations yet 🍽',
                  style: AppTypography.title.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Find a restaurant and book a table in seconds.',
                  textAlign: TextAlign.center,
                  style: AppTypography.subtitle,
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Explore restaurants',
                  onPressed: onExplorePressed,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Text(
                'Trending near you',
                style: AppTypography.title,
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 238,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trendingItems.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
              itemBuilder: (context, index) =>
                  _TrendingCard(item: trendingItems[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingCardData {
  const _TrendingCardData({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.code,
    required this.discountLabel,
    required this.imageUrl,
  });

  final String name;
  final double rating;
  final int reviews;
  final double distanceKm;
  final String code;
  final String discountLabel;
  final String imageUrl;
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.item});

  final _TrendingCardData item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 118,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.discountLabel,
                            style: AppTypography.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Limited time',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFBBF24),
                        size: 15,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${item.reviews} reviews',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Use code ${item.code}',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      Text(
                        '${item.distanceKm.toStringAsFixed(1)} km away',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RedemptionList extends StatelessWidget {
  final List<DealRedemption> redemptions;
  final Future<void> Function() onRefresh;
  final String emptyMessage;

  const _RedemptionList({
    required this.redemptions,
    required this.onRefresh,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (redemptions.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyStateWidget(
              icon: Icons.local_offer_outlined,
              title: emptyMessage,
              message: 'Pull to refresh or explore restaurants to get started.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          100,
        ),
        itemCount: redemptions.length,
        itemBuilder: (context, index) {
          return _RedemptionCard(redemption: redemptions[index]);
        },
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  final DealRedemption redemption;

  const _RedemptionCard({required this.redemption});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      onTap: () => _showRedemptionDetails(context, redemption),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      redemption.deal.restaurantName,
                      style: AppTypography.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      redemption.deal.title,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StatusBadge(isConfirmed: redemption.restaurantConfirmed),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Used: ${DateFormat('MMM d, yyyy HH:mm').format(redemption.usedAt)}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          if (redemption.redemptionCode != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.qr_code,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Code: ${redemption.redemptionCode}',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRedemptionDetails(BuildContext context, DealRedemption redemption) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RedemptionDetailModal(redemption: redemption),
    );
  }
}

class _RedemptionDetailModal extends StatelessWidget {
  final DealRedemption redemption;
  const _RedemptionDetailModal({required this.redemption});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              redemption.deal.restaurantName,
                              style: AppTypography.title.copyWith(
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _StatusBadge(
                              isConfirmed: redemption.restaurantConfirmed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // QR Code Logic
                      if (redemption.qrCodeUrl != null &&
                          redemption.qrCodeUrl!.isNotEmpty) ...[
                        Center(
                          child: AppCard(
                            padding:
                                const EdgeInsets.all(AppSpacing.lg),
                            child: Image.network(
                              redemption.qrCodeUrl!
                                  .replaceAll('localhost', '10.0.2.2')
                                  .replaceAll('127.0.0.1', '10.0.2.2'),
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) {
                                return const Icon(
                                  Icons.broken_image,
                                  size: 64,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      if (redemption.redemptionCode != null) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              redemption.redemptionCode!,
                              style: AppTypography.title.copyWith(
                                fontSize: 24,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],

                      _DetailRow(
                        icon: Icons.local_offer,
                        label: 'Offer',
                        value: redemption.deal.title,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (redemption.deal.discountPercentage != null)
                        _DetailRow(
                          icon: Icons.percent,
                          label: 'Discount',
                          value:
                              '${redemption.deal.discountPercentage!.toStringAsFixed(0)}% OFF',
                        ),
                      if (redemption.deal.discountAmount != null)
                        _DetailRow(
                          icon: Icons.attach_money,
                          label: 'Fixed discount',
                          value: '£${redemption.deal.discountAmount}',
                        ),

                      const SizedBox(height: AppSpacing.lg),
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: 'Used on',
                        value: DateFormat(
                          'EEEE, MMM d, yyyy HH:mm',
                        ).format(redemption.usedAt),
                      ),

                      if (redemption.notes != null &&
                          redemption.notes!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _DetailRow(
                          icon: Icons.note,
                          label: 'Notes',
                          value: redemption.notes!,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
              SecondaryButton(
                label: 'View restaurant',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailsPage(
                        slug: redemption.deal.restaurantSlug,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
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
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption,
              ),
              Text(
                value,
                style: AppTypography.body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isConfirmed;

  const _StatusBadge({required this.isConfirmed});

  @override
  Widget build(BuildContext context) {
    // If restaurant_confirmed is true -> Confirmed (Green)
    // If false -> Pending/Active (Orange)

    final color = isConfirmed
        ? AppColors.success
        : AppColors.discount;
    final text = isConfirmed ? 'Confirmed' : 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
