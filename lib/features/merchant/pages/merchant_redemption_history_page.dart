import 'package:flutter/material.dart';
import 'package:discount_buddy/core/theme/app_design.dart';
import 'package:discount_buddy/features/merchant/data/merchant_provider.dart';
import 'package:discount_buddy/components/layout.dart';
import 'package:discount_buddy/widgets/skeleton_loader.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/widgets/empty_state_widget.dart';

class MerchantRedemptionHistoryPage extends StatefulWidget {
  final int? restaurantId;
  final String? restaurantName;

  const MerchantRedemptionHistoryPage({
    super.key,
    this.restaurantId,
    this.restaurantName,
  });

  @override
  State<MerchantRedemptionHistoryPage> createState() => _MerchantRedemptionHistoryPageState();
}

class _MerchantRedemptionHistoryPageState extends State<MerchantRedemptionHistoryPage> {
  final MerchantProvider _merchantProvider = MerchantProvider();
  bool _isLoading = true;
  List<Map<String, dynamic>> _redemptionHistory = [];
  List<Map<String, dynamic>> _restaurants = [];
  int? _selectedRestaurantId;
  bool _isLoadingRestaurants = true;

  @override
  void initState() {
    super.initState();
    _selectedRestaurantId = widget.restaurantId;
    _loadRestaurants();
    _fetchRedemptionHistory();
  }

  Future<void> _loadRestaurants() async {
    try {
      setState(() => _isLoadingRestaurants = true);
      final restaurantsResult = await _merchantProvider.getMerchantRestaurants();
      final restaurants = restaurantsResult.valueOrNull ?? [];
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          _isLoadingRestaurants = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRestaurants = false);
      }
    }
  }

  Future<void> _fetchRedemptionHistory() async {
    setState(() => _isLoading = true);
    try {
      final historyResult = await _merchantProvider.getMerchantRedemptionHistory(
        restaurantId: _selectedRestaurantId,
      );
      final history = historyResult.valueOrNull ?? [];
      if (mounted) {
        setState(() {
          _redemptionHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Redemption History',
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildRestaurantFilter(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchRedemptionHistory,
              color: AppColors.primary,
              child: _isLoading 
                  ? _buildLoadingState()
                  : _redemptionHistory.isEmpty
                      ? _buildEmptyState()
                      : _buildHistoryList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantFilter() {
    if (_isLoadingRestaurants && _restaurants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        scrollDirection: Axis.horizontal,
        itemCount: _restaurants.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final restaurant = isAll ? null : _restaurants[index - 1];
          final id = isAll ? null : restaurant!['id'];
          final name = isAll ? 'All Restaurants' : restaurant!['name'];
          final isSelected = _selectedRestaurantId == id;

          return Center(
            child: GestureDetector(
              onTap: () {
                if (isSelected) return;
                setState(() {
                  _selectedRestaurantId = id;
                });
                _fetchRedemptionHistory();
              },
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
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: SkeletonLoader(height: 100, borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyStateWidget(
        icon: Icons.history_rounded,
        title: 'No Redemptions Yet',
        message: 'When customers redeem deals at your restaurant, they will appear here.',
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: _redemptionHistory.length,
      itemBuilder: (context, index) {
        final redemption = _redemptionHistory[index];
        final deal = redemption['deal_details'] ?? {};
        final redeemedAt = DateTime.tryParse(redemption['redeemed_at'] ?? '') ?? DateTime.now();
        
        return AppCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal['name'] ?? 'Mystery Deal',
                      style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Redeemed • ${_formatDateTime(redeemedAt)}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '£${redemption['price']?.toString() ?? '0.00'}',
                    style: AppTypography.title.copyWith(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${redemption['people_count'] ?? 1} people',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} • ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
