import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/restaurant.dart';
import '../../providers/theme_provider.dart';

/// Redeem Offer Modal - NeoTaste style bottom sheet
class RedeemOfferModal extends StatefulWidget {
  final Restaurant restaurant;

  const RedeemOfferModal({
    super.key,
    required this.restaurant,
  });

  @override
  State<RedeemOfferModal> createState() => _RedeemOfferModalState();
}

class _RedeemOfferModalState extends State<RedeemOfferModal> {
  bool _isRedeeming = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
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
            
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NeoTasteColors.accent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer,
                color: NeoTasteColors.accent,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: NeoTasteColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Deal Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NeoTasteColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: NeoTasteColors.accent,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.restaurant.discount.displayText,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.restaurant.discount.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: NeoTasteColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Warning Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'This offer will be activated for 15 minutes. Please show this to the staff when ordering.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: NeoTasteColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            
            // Confirm Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRedeeming ? null : () {
                    setState(() {
                      _isRedeeming = true;
                    });
                    
                    // Simulate redemption
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Offer redeemed successfully!',
                              style: GoogleFonts.inter(),
                            ),
                            backgroundColor: NeoTasteColors.accent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeoTasteColors.accent,
                    foregroundColor: NeoTasteColors.primary,
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
                              NeoTasteColors.primary,
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
}
