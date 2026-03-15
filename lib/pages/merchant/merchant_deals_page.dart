import 'package:flutter/material.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/design/app_spacing.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:discount_buddy/components/layout.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import '../../services/merchant_service.dart';
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
          SnackBar(content: Text('Failed to load deals: ${e.toString()}')),
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
        titleText: 'Deals',
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddDealPage()),
              ).then((_) => _loadDeals());
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _deals.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadDeals,
              color: AppColors.accent,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.xl),
                itemCount: _deals.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, index) {
                  final deal = _deals[index];
                  return _DealCard(deal: deal);
                },
              ),
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
          height: 120,
          borderRadius: BorderRadius.circular(16),
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

  const _DealCard({required this.deal});

  String _getDealTypeText(String? dealType) {
    switch (dealType) {
      case 'two_for_one':
        return '2 for 1';
      case 'percentage':
        return '% Off';
      case 'fixed':
        return 'Fixed Price';
      default:
        return 'Deal';
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

    return AppCard(
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
                    Text(title, style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      restaurantName,
                      style: AppTypography.subtitle,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: AppTypography.caption.copyWith(
                    color: isActive ? AppColors.success : Colors.red,
                  ),
                ),
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
              const SizedBox(width: AppSpacing.sm),
              _InfoTag(
                icon: Icons.people_outline,
                label: '$usedCount${maxUses != null ? ' / $maxUses' : ''} used',
              ),
            ],
          ),
        ],
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
