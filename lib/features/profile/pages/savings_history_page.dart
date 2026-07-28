import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discount_buddy/core/theme/app_design.dart';
import 'package:intl/intl.dart';
import 'package:discount_buddy/components/layout.dart';
import 'package:get/get.dart';

import 'package:discount_buddy/components/buttons.dart';
import 'package:discount_buddy/features/deals/models/deal_redemption.dart';
import 'package:discount_buddy/features/profile/data/profile_provider.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/widgets/loading_widget.dart';
import 'package:discount_buddy/widgets/empty_state_widget.dart';

class SavingsHistoryPage extends StatefulWidget {
  const SavingsHistoryPage({super.key});

  @override
  State<SavingsHistoryPage> createState() => _SavingsHistoryPageState();
}

class _SavingsHistoryPageState extends State<SavingsHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().getDealRedemptions();
    });
  }

  Future<void> _loadData() async {
    await context.read<ProfileProvider>().getDealRedemptions();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Savings History',
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          final redemptions = profileProvider.dealRedemptions;
          final claimedRedemptions = <DealRedemption>[];
          for (final r in redemptions) {
            if (r.isRedeemed == true || r.restaurantConfirmed == true) {
              claimedRedemptions.add(r);
            }
          }
          claimedRedemptions.sort((a, b) {
            final dateA = a.usedAt;
            final dateB = b.usedAt;
            return dateB.compareTo(dateA);
          });

          return profileProvider.isLoading
              ? const Center(child: LoadingWidget(message: 'Loading your savings...'))
              : claimedRedemptions.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.savings_outlined,
                      title: 'No savings yet',
                      message: 'Your savings will appear here once you redeem a deal.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: claimedRedemptions.length,
                        itemBuilder: (context, index) {
                          return _SavingsCard(redemption: claimedRedemptions[index]);
                        },
                      ),
                    );
        },
      ),
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
                  redemption.restaurantName,
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
                    redemption.restaurantName,
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
                Get.toNamed(
                  AppRoutes.restaurantDetails,
                  arguments: {
                    'slug': redemption.deal?.restaurantSlug ?? redemption.restaurantId.toString(),
                  },
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
