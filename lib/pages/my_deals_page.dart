import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design/app_colors.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';
import '../design/app_radius.dart';
import '../design/app_shadows.dart';
import '../services/restaurant_service.dart';
import '../widgets/loading_widget.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Deals',
          style: AppTypography.title.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xLarge,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
      ),
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
}
