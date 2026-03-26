import 'package:discount_buddy/design/app_colors.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';
import '../components/layout.dart';
import '../components/buttons.dart';
import '../models/deal_redemption.dart';
import '../services/restaurant_service.dart';
import 'restaurant_details_page.dart';
import '../widgets/app_scaffold.dart';
import '../components/app_app_bar.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

class SavingsHistoryPage extends StatefulWidget {
  const SavingsHistoryPage({super.key});

  @override
  State<SavingsHistoryPage> createState() => _SavingsHistoryPageState();
}

class _SavingsHistoryPageState extends State<SavingsHistoryPage> {
  final RestaurantService _restaurantService = RestaurantService();
  List<DealRedemption> _redemptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final redemptions = await _restaurantService.getUserDealRedemptions();
      // Filter for confirmed (claimed) redemptions and sort by date desc
      final claimedRedemptions = redemptions.where((r) => r.isRedeemed || r.restaurantConfirmed).toList()
        ..sort((a, b) => b.usedAt.compareTo(a.usedAt));

      if (mounted) {
        setState(() {
          _redemptions = claimedRedemptions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load savings history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Savings History',
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget(message: 'Loading your savings...'))
          : _redemptions.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.savings_outlined,
                  title: 'No savings yet',
                  message: 'Your savings will appear here once you redeem a deal.',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _redemptions.length,
                    itemBuilder: (context, index) {
                      return _SavingsCard(redemption: _redemptions[index]);
                    },
    );
  }
}

class _SavingsCard extends StatelessWidget {
  final DealRedemption redemption;

  const _SavingsCard({required this.redemption});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      onTap: () => _showDetails(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  redemption.deal.restaurantName,
                  style: AppTypography.title.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '£${redemption.discountAmountSaved?.toStringAsFixed(2) ?? '0.00'}',
                style: AppTypography.title.copyWith(
                  color: AppColors.success,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMMM d, yyyy').format(redemption.usedAt),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Savings',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SafeArea(
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
            Center(
              child: Column(
                children: [
                  Text(
                    redemption.deal.restaurantName,
                    style: AppTypography.title.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(redemption.usedAt),
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            _DetailRow(
              icon: Icons.receipt_long,
              label: 'Total Bill',
              value: '£${redemption.price?.toStringAsFixed(2) ?? '0.00'}',
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(
              icon: Icons.savings,
              label: 'Total Saved',
              value: '£${redemption.discountAmountSaved?.toStringAsFixed(2) ?? '0.00'}',
              valueColor: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(
              icon: Icons.payments,
              label: 'Final Amount Paid',
              value: '£${redemption.finalBillAmount?.toStringAsFixed(2) ?? '0.00'}',
              isBold: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(
              icon: Icons.people,
              label: 'Number of People',
              value: '${redemption.peopleCount ?? 1}',
            ),
            const SizedBox(height: AppSpacing.xxxl),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: 'View Restaurant',
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
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
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
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
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
