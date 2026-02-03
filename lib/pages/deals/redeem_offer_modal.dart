import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../providers/theme_provider.dart';

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
    final deals = widget.restaurant.activeDeals.isNotEmpty
        ? widget.restaurant.activeDeals
        : [widget.restaurant.discount];

    return Container(
      decoration: const BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: NeoTasteColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Redeem Offer',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NeoTasteColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Restaurant Name
              Text(
                widget.restaurant.name,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: NeoTasteColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Offers List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select an offer:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NeoTasteColors.textPrimary,
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
                              ? Colors.green.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.green
                                : NeoTasteColors.textDisabled.withOpacity(0.3),
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
                          activeColor: Colors.green,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            deal.displayText,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: NeoTasteColors.textPrimary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              deal.description,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: NeoTasteColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Warning Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
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
                              await restaurantService.claimDeal(dealId);

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Offer redeemed successfully!',
                                      style: GoogleFonts.inter(),
                                    ),
                                    backgroundColor: Colors.green,
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
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: NeoTasteColors.white,
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
                                NeoTasteColors.white,
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
      ),
    );
  }
}
