import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../design/app_radius.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../components/buttons.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../widgets/generic_bottom_sheet.dart';
import '../../config/environment.dart';

/// Redeem Offer Modal - NeoTaste style bottom sheet
class RedeemOfferModal extends StatefulWidget {
  final Restaurant restaurant;

  const RedeemOfferModal({super.key, required this.restaurant});

  @override
  State<RedeemOfferModal> createState() => _RedeemOfferModalState();
}

class _RedeemOfferModalState extends State<RedeemOfferModal> {
  bool _isRedeeming = false;
  late dynamic _selectedOption; // Can be a Discount or 'loyalty'
  Map<String, dynamic>? _redemptionResult;

  @override
  void initState() {
    super.initState();
    final deals = widget.restaurant.activeDeals
        .where((d) => d.type != 'none')
        .toList();
    if (deals.isNotEmpty) {
      _selectedOption = deals.first;
    } else if (widget.restaurant.loyaltyCardEnabled) {
      _selectedOption = 'loyalty';
    } else {
      _selectedOption = widget.restaurant.discount;
    }
  }

  Future<void> _confirmRedemption() async {
    setState(() => _isRedeeming = true);
    try {
      Map<String, dynamic> result;
      if (_selectedOption == 'loyalty') {
        final slug = widget.restaurant.slug ?? widget.restaurant.id;
        result = await RestaurantService().createLoyaltyOnlyVisit(slug);
      } else if (_selectedOption is Discount) {
        final dealId = (_selectedOption as Discount).id;
        if (dealId == null) {
          throw Exception('Please select a valid offer');
        }
        result = await RestaurantService().claimDeal(dealId);
      } else {
        throw Exception('Please select a valid option');
      }

      if (mounted) {
        setState(() {
          _isRedeeming = false;
          _redemptionResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRedeeming = false);
        String errorMessage = e.toString();
        if (errorMessage.contains('maximum uses') ||
            errorMessage.contains(
              'You have reached the maximum uses for this deal',
            )) {
          errorMessage = "You've used offer already";
        } else {
          errorMessage = errorMessage.replaceAll('Exception: ', '');
        }
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Redemption Failed'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_redemptionResult != null) {
      return _buildSuccessView();
    }

    final deals = widget.restaurant.activeDeals
        .where((d) => d.type != 'none')
        .toList();

    final showList = deals.isNotEmpty || widget.restaurant.loyaltyCardEnabled;

    return GenericBottomSheet(
      title: 'Redeem Offer',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Restaurant Name
            Text(
              widget.restaurant.name,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),

            if (!showList)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                child: Column(
                  children: [
                    Icon(Icons.local_offer_outlined,
                        size: 48, color: AppColors.textDisabled),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No active offers available',
                      style: AppTypography.subtitle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deals.isNotEmpty ? 'Select an option:' : 'Loyalty Program Check-in:',
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    // Render deals
                    if (deals.isNotEmpty)
                      ...deals.map((deal) {
                        final isSelected = _selectedOption is Discount && (_selectedOption as Discount).id == deal.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withAlpha((0.05 * 255).toInt())
                                : AppColors.surface,
                            borderRadius: AppRadius.large,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [] : AppShadows.card,
                          ),
                          child: Column(
                            children: [
                              RadioListTile<dynamic>(
                                value: deal,
                                groupValue: _selectedOption,
                                toggleable: true,
                                activeColor: AppColors.primary,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.medium,
                                ),
                                title: Text(
                                  deal.displayText,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding:
                                      const EdgeInsets.only(top: AppSpacing.xs),
                                  child: Text(
                                    deal.description,
                                    style: AppTypography.bodySmall,
                                  ),
                                ),
                                onChanged: (dynamic value) {
                                  setState(() {
                                    _selectedOption = value;
                                  });
                                },
                              ),
                              if (isSelected &&
                                  (deal.termsAndConditions.isNotEmpty ||
                                      deal.maxPerUser > 0 ||
                                      deal.percentage != null ||
                                      deal.fixedAmount != null ||
                                      deal.minimumSpendAmount != null))
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      const SizedBox(height: AppSpacing.xs),
                                      if (deal.percentage != null && deal.percentage! > 0)
                                        Text(
                                          '• Discount: ${deal.percentage!.toInt()}% off',
                                          style: AppTypography.caption,
                                        )
                                      else if (deal.fixedAmount != null && deal.fixedAmount! > 0)
                                        Text(
                                          '• Discount: £${deal.fixedAmount!.toStringAsFixed(2)} off',
                                          style: AppTypography.caption,
                                        )
                                      else if (deal.type == 'combo' && deal.comboPrice != null)
                                        Text(
                                          '• Combo Price: £${deal.comboPrice!.toStringAsFixed(2)}',
                                          style: AppTypography.caption,
                                        ),
                                      if (deal.type != 'combo' && deal.minimumSpendAmount != null && deal.minimumSpendAmount! > 0)
                                        Text(
                                          '• Minimum spend: £${deal.minimumSpendAmount!.toStringAsFixed(2)}',
                                          style: AppTypography.caption,
                                        ),
                                      if (deal.maxPerUser > 0)
                                        Text(
                                          '• Max uses per user: ${deal.maxPerUser}',
                                          style: AppTypography.caption,
                                        ),
                                      if (deal.termsAndConditions.isNotEmpty)
                                        Text(
                                          '• ${deal.termsAndConditions}',
                                          style: AppTypography.caption,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),

                    // Render loyalty check-in if enabled
                    if (widget.restaurant.loyaltyCardEnabled) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: _selectedOption == 'loyalty'
                              ? AppColors.primary.withAlpha((0.05 * 255).toInt())
                              : AppColors.surface,
                          borderRadius: AppRadius.large,
                          border: Border.all(
                            color: _selectedOption == 'loyalty'
                                ? AppColors.primary
                                : AppColors.cardBorder,
                            width: _selectedOption == 'loyalty' ? 2 : 1,
                          ),
                          boxShadow: _selectedOption == 'loyalty' ? [] : AppShadows.card,
                        ),
                        child: RadioListTile<dynamic>(
                          value: 'loyalty',
                          groupValue: _selectedOption,
                          toggleable: true,
                          activeColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                          title: Text(
                            'Loyalty Point Check-In',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              'Collect a stamp towards a free reward.',
                              style: AppTypography.bodySmall,
                            ),
                          ),
                          onChanged: (dynamic value) {
                            setState(() {
                              _selectedOption = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.lg),
            if (showList) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: AppRadius.large,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _selectedOption == 'loyalty'
                              ? 'Check-in QR codes must be scanned by staff to credit a point to your card.'
                              : 'Activated offers last for 15 mins. Show to staff when ordering.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: PrimaryButton(
                  label: _selectedOption == 'loyalty' ? 'Get Check-In QR' : 'Confirm Redemption',
                  onPressed: _isRedeeming ? null : _confirmRedemption,
                  isLoading: _isRedeeming,
                  expand: true,
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: SecondaryButton(
                  label: 'Close',
                  onPressed: () => Navigator.pop(context),
                  expand: true,
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    String qrUrl = _redemptionResult!['qr_code_url'] ?? '';
    final code = _redemptionResult!['redemption_code'] ?? 'Unknown';
    final isLoyalty = _selectedOption == 'loyalty';

    // Replace localhost/127.0.0.1 with correct base URL if needed
    if (qrUrl.contains('127.0.0.1') || qrUrl.contains('localhost')) {
      // Remove generic ports if present to be safe or just string replace
      qrUrl = qrUrl.replaceAll('http://127.0.0.1:8000', Environment.baseUrl);
      qrUrl = qrUrl.replaceAll('http://localhost:8000', Environment.baseUrl);
    }

    return GenericBottomSheet(
      title: isLoyalty ? 'Loyalty Check-In Created' : 'Redemption Successful',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isLoyalty
                ? 'Show this Check-in QR to staff to collect your stamp'
                : 'Show this QR code to the staff',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // QR Code
          if (qrUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.xLarge,
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppShadows.card,
              ),
              child: Image.network(
                qrUrl,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: Icon(
                        Icons.qr_code_2,
                        size: 64,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Or provide this code:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.large,
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppShadows.card,
            ),
            child: Text(
              code.toString(),
              style: AppTypography.headline.copyWith(
                fontSize: 32,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.large,
                ),
              ),
              child: Text(
                'Done',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
