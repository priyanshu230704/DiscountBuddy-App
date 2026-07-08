import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../design/app_colors.dart';
import '../../design/app_radius.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../models/loyalty_card.dart';
import '../../services/restaurant_service.dart';
import '../../routes/app_routes.dart';
import '../../config/environment.dart';
import '../../widgets/generic_bottom_sheet.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_gradient_button.dart';
import '../../components/app_app_bar.dart';

/// Loyalty Cards Screen - Loyalty Wallet where customers track all their active stamps
class LoyaltyCardsScreen extends StatefulWidget {
  const LoyaltyCardsScreen({super.key});

  static Route<dynamic> route() =>
      MaterialPageRoute(builder: (_) => const LoyaltyCardsScreen());

  @override
  State<LoyaltyCardsScreen> createState() => _LoyaltyCardsScreenState();
}

class _LoyaltyCardsScreenState extends State<LoyaltyCardsScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  bool _isLoading = true;
  List<LoyaltyCard> _cards = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLoyaltyCards();
  }

  Future<void> _loadLoyaltyCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cards = await _restaurantService.getLoyaltyCards();
      if (mounted) {
        setState(() {
          _cards = cards.where((c) => c.restaurant.loyaltyCardEnabled).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showRewardQrDialog(LoyaltyCard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GenericBottomSheet(
        title: 'Claim Reward',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                card.restaurant.name,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'REWARD UNLOCKED',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (card.rewardQrCode != null &&
                        card.rewardQrCode!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          card.rewardQrCode!
                              .replaceAll(
                                'http://127.0.0.1:8000',
                                Environment.baseUrl,
                              )
                              .replaceAll(
                                'http://localhost:8000',
                                Environment.baseUrl,
                              ),
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              width: 180,
                              height: 180,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 180,
                                height: 180,
                                color: AppColors.cardBorder,
                                child: const Center(
                                  child: Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 64,
                                    color: AppColors.textDisabled,
                                  ),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (card.rewardCode != null &&
                        card.rewardCode!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBorder.withAlpha(
                            (0.4 * 255).toInt(),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          card.rewardCode!,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
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
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStampGrid(int completed, int requiredVal, bool isEligible) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(requiredVal, (index) {
        final isStamped = index < completed;
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isStamped
                ? (isEligible
                      ? AppColors.success.withAlpha((0.1 * 255).toInt())
                      : AppColors.primary.withAlpha((0.1 * 255).toInt()))
                : Colors.transparent,
            border: Border.all(
              color: isStamped
                  ? (isEligible ? AppColors.success : AppColors.primary)
                  : AppColors.cardBorder,
              width: isStamped ? 2 : 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              isStamped ? Icons.star_rounded : Icons.star_border_rounded,
              size: 20,
              color: isStamped
                  ? (isEligible ? AppColors.success : AppColors.primary)
                  : AppColors.textDisabled,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'My Loyalty Cards',
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _loadLoyaltyCards,
        color: AppColors.primary,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Something went wrong',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _loadLoyaltyCards,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cards.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.card_membership_rounded,
                      size: 64,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No Loyalty Cards Yet',
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Scan check-in QRs or redeem deals at participating restaurants to start earning rewards.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.md,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        final completed = card.completedRedemptions;
        final requiredVal = card.requiredRedemptions;
        final isEligible = card.isRewardEligible;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.xLarge,
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.toNamed(
                  AppRoutes.restaurantDetails,
                  arguments: {
                    'slug':
                        card.restaurant.slug ?? card.restaurant.id.toString(),
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.medium,
                          child: card.restaurant.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: card.restaurant.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: 60,
                                        height: 60,
                                        color: AppColors.divider,
                                        child: const Icon(
                                          Icons.storefront,
                                          color: AppColors.textDisabled,
                                        ),
                                      ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.divider,
                                  child: const Icon(
                                    Icons.storefront,
                                    color: AppColors.textDisabled,
                                  ),
                                ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.restaurant.name,
                                style: AppTypography.title.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                isEligible
                                    ? 'Free Reward Unlocked!'
                                    : card
                                              .restaurant
                                              .loyaltyRewardDescription ??
                                          'Collect Stamps',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isEligible
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  fontWeight: isEligible
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: AppSpacing.lg),

                    // Visual Coffee Card Style Stamps Grid
                    _buildStampGrid(completed, requiredVal, isEligible),

                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEligible
                              ? 'Reward Unlocked!'
                              : '$completed of $requiredVal stamps collected',
                          style: AppTypography.caption.copyWith(
                            color: isEligible
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: isEligible
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (!isEligible)
                          Text(
                            '${requiredVal - completed} left',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    if (isEligible) ...[
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: AppGradientButton(
                          onPressed: () => _showRewardQrDialog(card),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.qr_code_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Show Reward QR',
                                style: AppTypography.button.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
