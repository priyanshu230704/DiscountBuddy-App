import 'package:discount_buddy/features/auth/domain/entities/user_entity.dart';
import 'package:discount_buddy/features/auth/models/api_user.dart';

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
}
