import 'package:flutter/material.dart';
import '../../services/merchant_service.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../components/layout.dart';
import '../../components/app_app_bar.dart';
import '../../widgets/skeleton_loader.dart';
import 'add_deal_page.dart';

/// Merchant Deals Management Page
class MerchantDealsPage extends StatefulWidget {
  final int? restaurantId;
  const MerchantDealsPage({super.key, this.restaurantId});

  @override
  State<MerchantDealsPage> createState() => _MerchantDealsPageState();
}

class _MerchantDealsPageState extends State<MerchantDealsPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _deals = [];
  List<Map<String, dynamic>> _restaurants = [];
  int? _selectedRestaurantId;
  bool _isLoading = true;
  bool _isFetching = false;
  bool _isLoadingRestaurants = true;

  @override
  void initState() {
    super.initState();
    _selectedRestaurantId = widget.restaurantId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRestaurants();
      _loadDeals();
    });
  }

  Future<void> _loadRestaurants() async {
    try {
      setState(() => _isLoadingRestaurants = true);
      final restaurants = await _merchantService.getMerchantRestaurants();
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

  Future<void> _loadDeals() async {
    if (!mounted || _isFetching) return;

    try {
      setState(() {
        _isLoading = true;
        _isFetching = true;
      });

      final deals = await _merchantService.getMerchantDeals(
        restaurantId: _selectedRestaurantId,
      );
      if (mounted) {
        setState(() {
          _deals = deals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load deals: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        _isFetching = false;
      }
    }
  }

  Future<void> _toggleDealStatus(int dealId) async {
    try {
      final response = await _merchantService.toggleDealStatus(dealId);
      if (mounted && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['detail'] ?? 'Status updated'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        _loadDeals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        titleText: 'Active Deals',
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryOrange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddDealPage()),
              ).then((_) => _loadDeals());
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRestaurantFilter(),
          if (!_isLoading && _deals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
              child: Text(
                '${_deals.where((d) => d['is_active'] == true).length} Active Deal${_deals.where((d) => d['is_active'] == true).length == 1 ? '' : 's'}',
                style: AppTypography.title.copyWith(fontSize: 18),
              ),
            ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _deals.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadDeals,
                    color: AppColors.primaryOrange,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.sm,
                        AppSpacing.xl,
                        AppSpacing.xxxl,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _deals.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, index) {
                        return _DealCard(
                          deal: _deals[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddDealPage(deal: _deals[index]),
                              ),
                            ).then((_) => _loadDeals());
                          },
                          onToggle: (isActive) {
                            _toggleDealStatus(_deals[index]['id']);
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: SkeletonLoader(
          height: 140,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.local_offer_rounded,
      title: 'No active deals',
      message: 'Create a deal to attract more customers.',
      primaryActionLabel: 'Create deal',
      onPrimaryAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddDealPage()),
        ).then((_) => _loadDeals());
      },
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

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedRestaurantId = id;
              });
              _loadDeals();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Text(
                name,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Map<String, dynamic> deal;
  final VoidCallback onTap;
  final Function(bool) onToggle;

  const _DealCard({
    required this.deal,
    required this.onTap,
    required this.onToggle,
  });

  String _getDealTypeText(String? dealType) {
    switch (dealType) {
      case 'two_for_one':
        return '2-for-1 Deal';
      case 'percentage':
        return '% Discount';
      case 'fixed':
        return 'Fixed Price';
      default:
        return 'Offer';
    }
  }

  IconData _getDealIcon(String? dealType) {
    switch (dealType) {
      case 'two_for_one':
        return Icons.people_alt_rounded;
      case 'percentage':
        return Icons.percent_rounded;
      case 'fixed':
        return Icons.attach_money_rounded;
      default:
        return Icons.local_offer_rounded;
    }
  }

  Color _getDealColor(String? dealType) {
    switch (dealType) {
      case 'two_for_one':
        return AppColors.merchantIndigo;
      case 'percentage':
        return AppColors.merchantAmber;
      case 'fixed':
        return AppColors.merchantTeal;
      default:
        return AppColors.primaryOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = deal['restaurant'] as Map<String, dynamic>?;
    final restaurantName = restaurant?['name'] ?? 'Unknown Restaurant';
    final title = deal['title'] ?? 'Untitled Deal';
    final dealType = deal['deal_type'] as String?;
    final isActive = deal['is_active'] as bool? ?? false;
    final usedCount = deal['used_count'] as int? ?? 0;
    final maxUses = deal['max_uses'] as int?;

    final iconColor = _getDealColor(dealType);
    final iconData = _getDealIcon(dealType);

    double progress = 0;
    if (maxUses != null && maxUses > 0) {
      progress = (usedCount / maxUses).clamp(0.0, 1.0);
    }

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.title.copyWith(fontSize: 17),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      restaurantName,
                      style: AppTypography.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch.adaptive(
                value: isActive,
                onChanged: onToggle,
                activeThumbColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _InfoTag(
                icon: Icons.local_offer_outlined,
                label: _getDealTypeText(dealType),
              ),
              const Spacer(),
              if (maxUses != null)
                Text(
                  '$usedCount / $maxUses used',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  '$usedCount used',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (maxUses != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.shimmer,
                color: progress > 0.9 ? AppColors.error : AppColors.merchantBlue,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
