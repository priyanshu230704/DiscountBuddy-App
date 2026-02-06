import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/generic_bottom_sheet.dart';

/// Redeem Offer Modal - Redesigned
class RedeemOfferModal extends StatefulWidget {
  final Restaurant restaurant;

  const RedeemOfferModal({super.key, required this.restaurant});

  @override
  State<RedeemOfferModal> createState() => _RedeemOfferModalState();
}

class _RedeemOfferModalState extends State<RedeemOfferModal> {
  bool _isRedeeming = false;
  late Discount _selectedDeal;

  @override
  void initState() {
    super.initState();
    // Default to the first deal or the primary discount
    _selectedDeal = widget.restaurant.activeDeals.isNotEmpty
        ? widget.restaurant.activeDeals.first
        : widget.restaurant.discount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final deals = widget.restaurant.activeDeals.isNotEmpty
        ? widget.restaurant.activeDeals
        : [widget.restaurant.discount];

    return GenericBottomSheet(
      title: 'Redeem Offer',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Restaurant Name
            Text(
              widget.restaurant.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Offers List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select an offer:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...deals.map((deal) {
                    final isSelected =
                        _selectedDeal.id == deal.id ||
                        (_selectedDeal.id == null && deals.length == 1);
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXl,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.dividerDark
                                    : AppColors.dividerLight),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: RadioListTile<Discount>(
                        value: deal,
                        groupValue: _selectedDeal,
                        onChanged: (Discount? value) {
                          if (value != null) {
                            setState(() {
                              _selectedDeal = value;
                            });
                          }
                        },
                        toggleable: true,
                        activeColor: AppColors.primary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXl,
                          ),
                        ),
                        title: Text(
                          deal.displayText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            deal.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Warning Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Activated offers last for 15 mins. Show to staff when ordering.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.amber[200] : Colors.brown[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isRedeeming
                      ? null
                      : () async {
                          final dealId = _selectedDeal.id;
                          if (dealId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a valid offer'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _isRedeeming = true;
                          });

                          try {
                            final RestaurantService restaurantService =
                                RestaurantService();
                            await restaurantService.claimDeal(dealId);

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Offer redeemed successfully!',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _isRedeeming = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: _isRedeeming
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Confirm Redemption',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
