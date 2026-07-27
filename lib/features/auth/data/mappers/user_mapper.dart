import 'package:discount_buddy/features/auth/domain/entities/user_entity.dart';
import 'package:discount_buddy/features/auth/models/api_user.dart';
import 'package:discount_buddy/features/restaurants/models/image_variants.dart';

class UserMapper {
  const UserMapper();

  UserEntity toEntity(ApiUser dto, {String? roleOverride}) {
    final role = roleOverride ??
        dto.profile?.role ??
        (dto.isMerchant ? 'merchant' : 'customer');
    return UserEntity(
      id: dto.id,
      email: dto.email,
      username: dto.username,
      isMerchant: dto.isMerchant,
      isCustomer: dto.isCustomer,
      role: role,
      phoneNumber: dto.profile?.phoneNumber,
      profilePictureUrl: dto.profilePicture,
      marketingOptIn: dto.profile?.marketingOptIn ?? true,
      activeRestaurantsCount: dto.loyaltyStats?.activeRestaurantsCount,
      rewardEligibleCount: dto.loyaltyStats?.rewardEligibleCount,
    );
  }

  /// Compatibility shim for existing UI that still expects [ApiUser].
  ApiUser toDto(UserEntity entity) {
    return ApiUser(
      id: entity.id,
      email: entity.email,
      username: entity.username,
      isMerchant: entity.isMerchant,
      isCustomer: entity.isCustomer,
      profile: UserProfile(
        role: entity.role,
        phoneNumber: entity.phoneNumber,
        profilePicture: entity.profilePictureUrl != null
            ? ImageVariants(
                medium: entity.profilePictureUrl,
                large: entity.profilePictureUrl,
              )
            : const ImageVariants(),
        marketingOptIn: entity.marketingOptIn,
      ),
      loyaltyStats: (entity.activeRestaurantsCount != null ||
              entity.rewardEligibleCount != null)
          ? UserLoyaltyStats(
              activeRestaurantsCount: entity.activeRestaurantsCount ?? 0,
              rewardEligibleCount: entity.rewardEligibleCount ?? 0,
            )
          : null,
    );
  }
}
