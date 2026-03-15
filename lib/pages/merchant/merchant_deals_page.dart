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
  const MerchantDealsPage({super.key});

  @override
  State<MerchantDealsPage> createState() => _MerchantDealsPageState();
}

class _MerchantDealsPageState extends State<MerchantDealsPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _deals = [];
  bool _isLoading = true;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeals();
    });
  }

  Future<void> _loadDeals() async {
    if (!mounted || _isFetching) return;

    try {
      setState(() {
        _isLoading = true;
        _isFetching = true;
      });

      final deals = await _merchantService.getMerchantDeals();
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
          if (!_isLoading && _deals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
              child: Text(
                '${_deals.length} Active Deal${_deals.length == 1 ? '' : 's'}',
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
}

class _DealCard extends StatelessWidget {
  final Map<String, dynamic> deal;
  final VoidCallback onTap;

  const _DealCard({required this.deal, required this.onTap});

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
              _StatusBadge(isActive: isActive),
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

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;
    final bg = isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
