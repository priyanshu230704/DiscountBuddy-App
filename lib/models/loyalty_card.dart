import 'restaurant.dart';

/// Loyalty Card model representing a user's subscription/progress in a restaurant's loyalty program.
class LoyaltyCard {
  final int id;
  final Restaurant restaurant;
  final int requiredRedemptions;
  final int completedRedemptions;
  final bool isRewardEligible;
  final String? rewardCode;
  final String? rewardQrCode;

  LoyaltyCard({
    required this.id,
    required this.restaurant,
    required this.requiredRedemptions,
    required this.completedRedemptions,
    required this.isRewardEligible,
    this.rewardCode,
    this.rewardQrCode,
  });

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) {
    final restaurantId = json['restaurant_id']?.toString() ?? '';
    final restaurantName = json['restaurant_name'] as String? ?? '';
    final restaurantSlug = json['restaurant_slug'] as String? ?? '';
    final restaurantImage = json['restaurant_image'] as String? ?? '';

    final restaurant = Restaurant.fromJson(const {}).copyWith(
      id: restaurantId,
      name: restaurantName,
      imageUrl: restaurantImage,
      slug: restaurantSlug,
      loyaltyCardEnabled: true,
    );

    final programJson = json['loyalty_program'] as Map<String, dynamic>?;

    final requiredRedemptions = programJson != null
        ? (programJson['required_redemptions'] as int? ?? 6)
        : 6;

    final completedRedemptions = programJson != null
        ? (programJson['completed_redemptions'] as int? ?? 0)
        : (json['current_cycle_redemptions'] as int? ?? 0);

    final isRewardEligible = programJson != null
        ? (programJson['is_reward_eligible'] as bool? ?? json['is_reward_eligible'] as bool? ?? false)
        : (json['is_reward_eligible'] as bool? ?? false);

    final rewardCode = json['reward_code'] as String?;
    final rewardQrCode = json['reward_qr_url'] as String? ?? json['reward_qr_code'] as String?;

    return LoyaltyCard(
      id: json['id'] as int? ?? 0,
      restaurant: restaurant,
      requiredRedemptions: requiredRedemptions,
      completedRedemptions: completedRedemptions,
      isRewardEligible: isRewardEligible,
      rewardCode: rewardCode,
      rewardQrCode: rewardQrCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant': restaurant.toJson(),
      'required_redemptions': requiredRedemptions,
      'completed_redemptions': completedRedemptions,
      'is_reward_eligible': isRewardEligible,
      if (rewardCode != null) 'reward_code': rewardCode,
      if (rewardQrCode != null) 'reward_qr_code': rewardQrCode,
    };
  }
}
