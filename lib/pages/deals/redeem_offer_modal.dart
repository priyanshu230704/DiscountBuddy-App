import 'package:discount_buddy/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late Discount _selectedDeal;
  Map<String, dynamic>? _redemptionResult;

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
    if (_redemptionResult != null) {
      return _buildSuccessView();
    }

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
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Offers List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: RadioGroup<Discount>(
                groupValue: _selectedDeal,
                onChanged: (Discount? value) {
                  if (value != null) {
                    setState(() {
                      _selectedDeal = value;
                    });
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select an offer:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...deals.map((deal) {
                      final isSelected =
                          _selectedDeal.id == deal.id ||
                          (_selectedDeal.id == null && deals.length == 1);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryPurple.withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryPurple
                                : AppColors.textDisabled.withValues(
                                    alpha: 0.3,
                                  ),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: RadioListTile<Discount>(
                          value: deal,
                          toggleable: true,
                          activeColor: AppColors.primaryPurple,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          title: Text(
                            deal.displayText,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              deal.description,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Warning Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Activated offers last for 15 mins. Show to staff when ordering.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.brown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRedeeming
                      ? null
                      : () async {
                          final dealId = _selectedDeal.id;
                          if (dealId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a valid offer'),
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
                            final result = await restaurantService.claimDeal(
                              dealId,
                            );

                            if (mounted) {
                              setState(() {
                                _isRedeeming = false;
                                _redemptionResult = result;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _isRedeeming = false;
                              });

                              String errorMessage = e.toString();
                              // Check specifically for the maximum uses error
                              if (errorMessage.contains('maximum uses') ||
                                  errorMessage.contains(
                                    'You have reached the maximum uses for this deal',
                                  )) {
                                errorMessage = "You've used offer already";
                              } else {
                                // Clean up error message if needed (remove Exception: prefix)
                                errorMessage = errorMessage.replaceAll(
                                  'Exception: ',
                                  '',
                                );
                              }

                              /*
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errorMessage)),
                              );
                              */

                              // Show error in a dialog instead of snackbar to ensure it's visible over the modal
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
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isRedeeming
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Confirm Redemption',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    String qrUrl = _redemptionResult!['qr_code_url'] ?? '';
    final code = _redemptionResult!['redemption_code'] ?? 'Unknown';

    // Replace localhost/127.0.0.1 with correct base URL if needed
    if (qrUrl.contains('127.0.0.1') || qrUrl.contains('localhost')) {
      // Remove generic ports if present to be safe or just string replace
      qrUrl = qrUrl.replaceAll('http://127.0.0.1:8000', Environment.baseUrl);
      qrUrl = qrUrl.replaceAll('http://localhost:8000', Environment.baseUrl);
    }

    return GenericBottomSheet(
      title: 'Redemption Successful',
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
            'Show this QR code to the staff',
            style: GoogleFonts.inter(
              fontSize: 16,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.textDisabled.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
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
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textDisabled.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              code.toString(),
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
