/// Domain user — independent of API DTO shape.
class UserEntity {
  final int id;
  final String email;
  final String username;
  final bool isMerchant;
  final bool isCustomer;
  final String role;
  final String? phoneNumber;
  final String? profilePictureUrl;
  final bool marketingOptIn;
  final int? activeRestaurantsCount;
  final int? rewardEligibleCount;

  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    required this.isMerchant,
    required this.isCustomer,
    required this.role,
    this.phoneNumber,
    this.profilePictureUrl,
    this.marketingOptIn = true,
    this.activeRestaurantsCount,
    this.rewardEligibleCount,
  });

  bool get isMysteryGuest => role == 'mystery_guest';

  UserEntity copyWith({
    int? id,
    String? email,
    String? username,
    bool? isMerchant,
    bool? isCustomer,
    String? role,
    String? phoneNumber,
    String? profilePictureUrl,
    bool? marketingOptIn,
    int? activeRestaurantsCount,
    int? rewardEligibleCount,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      isMerchant: isMerchant ?? this.isMerchant,
      isCustomer: isCustomer ?? this.isCustomer,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
      activeRestaurantsCount:
          activeRestaurantsCount ?? this.activeRestaurantsCount,
      rewardEligibleCount: rewardEligibleCount ?? this.rewardEligibleCount,
    );
  }
}
