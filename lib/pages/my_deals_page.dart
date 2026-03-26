import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:intl/intl.dart';
import '../services/restaurant_service.dart';
import '../widgets/app_scaffold.dart';
import '../components/app_app_bar.dart';
import '../widgets/loading_widget.dart';
import 'package:discount_buddy/components/layout.dart' hide LoadingWidget;

class MyDealsPage extends StatefulWidget {
  const MyDealsPage({super.key});

  @override
  State<MyDealsPage> createState() => _MyDealsPageState();
}

class _MyDealsPageState extends State<MyDealsPage> {
  final RestaurantService _restaurantService = RestaurantService();
  List<dynamic> _claimedDeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() => _isLoading = true);
    try {
      final deals = await _restaurantService.getDealUses();
      if (mounted) {
        setState(() {
          _claimedDeals = deals;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'My Deals',
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading your deals...')
          : _claimedDeals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined, size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      Text(
                        'No deals claimed yet',
                        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDeals,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _claimedDeals.length,
                    itemBuilder: (context, index) {
                      final use = _claimedDeals[index];
                      return _DealUseCard(use: use);
                    },
                  ),
                ),
    );
  }
}

class _DealUseCard extends StatelessWidget {
  final dynamic use;

  const _DealUseCard({required this.use});

  @override
  Widget build(BuildContext context) {
    final deal = use.deal;
    final restaurant = deal.restaurantName;
    final date = use.usedAt;
    final isRedeemed = use.isRedeemed;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      onTap: () => _showRedemptionDetails(context, use),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  deal.title,
                  style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isRedeemed ? AppColors.success.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isRedeemed ? 'REDEEMED' : 'CLAIMED',
                  style: AppTypography.caption.copyWith(
                    color: isRedeemed ? AppColors.success : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            restaurant,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM d, yyyy HH:mm').format(date.toLocal()),
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          if (use.redemptionCode != null && !isRedeemed) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadius.medium,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Redemption Code: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    use.redemptionCode!,
                    style: const TextStyle(
                      letterSpacing: 2,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRedemptionDetails(BuildContext context, dynamic redemption) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RedemptionDetailModal(redemption: redemption),
    );
  }
}

class _RedemptionDetailModal extends StatelessWidget {
  final dynamic redemption;
  const _RedemptionDetailModal({required this.redemption});

  @override
  Widget build(BuildContext context) {
    final isRedeemed = redemption.isRedeemed;
    
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                              style: AppTypography.title.copyWith(fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _StatusBadge(isRedeemed: isRedeemed),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      _DetailRow(
                        icon: Icons.local_offer,
                        label: 'Offer',
                        value: redemption.deal.title,
                      ),
                      
                      if (isRedeemed && redemption.finalBillAmount != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(),
                        const SizedBox(height: AppSpacing.lg),
                        _DetailRow(
                          icon: Icons.receipt_long,
                          label: 'Total Bill',
                          value: '£${redemption.price?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailRow(
                          icon: Icons.savings,
                          label: 'Total Saved',
                          value: '£${redemption.discountAmountSaved?.toStringAsFixed(2) ?? '0.00'}',
                          valueColor: AppColors.success,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailRow(
                          icon: Icons.payments,
                          label: 'Final Amount Paid',
                          value: '£${redemption.finalBillAmount?.toStringAsFixed(2) ?? '0.00'}',
                          isBold: true,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailRow(
                          icon: Icons.people,
                          label: 'Number of People',
                          value: '${redemption.peopleCount ?? 1}',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(),
                      ],

                      const SizedBox(height: AppSpacing.lg),
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: 'Used on',
                        value: DateFormat('EEEE, MMM d, yyyy HH:mm').format(redemption.usedAt.toLocal()),
                      ),

                      if (redemption.redemptionCode != null && !isRedeemed) ...[
                        const SizedBox(height: AppSpacing.xxxl),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: AppRadius.large,
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              children: [
                                Text('Redemption Code', style: AppTypography.caption),
                                const SizedBox(height: 8),
                                Text(
                                  redemption.redemptionCode!,
                                  style: AppTypography.title.copyWith(
                                    fontSize: 32,
                                    letterSpacing: 8,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxxl),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
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
              Text(label, style: AppTypography.caption),
              Text(
                value,
                style: AppTypography.body.copyWith(
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isRedeemed;
  const _StatusBadge({required this.isRedeemed});

  @override
  Widget build(BuildContext context) {
    final color = isRedeemed ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        isRedeemed ? 'REDEEMED' : 'CLAIMED',
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
