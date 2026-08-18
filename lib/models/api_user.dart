import 'image_variants.dart';

/// User Loyalty Stats model
class UserLoyaltyStats {
  final int activeRestaurantsCount;
  final int rewardEligibleCount;

  UserLoyaltyStats({
    required this.activeRestaurantsCount,
    required this.rewardEligibleCount,
  });

  factory UserLoyaltyStats.fromJson(Map<String, dynamic> json) {
    return UserLoyaltyStats(
      activeRestaurantsCount: json['active_restaurants_count'] as int? ?? 0,
      rewardEligibleCount: json['reward_eligible_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active_restaurants_count': activeRestaurantsCount,
      'reward_eligible_count': rewardEligibleCount,
    };
  }
}

/// API User model matching the API response structure
class ApiUser {
  final int id;
  final String email;
  final String username;
  final bool isMerchant;
  final bool isCustomer;
  final bool isAdmin;
  final bool isSuperuser;
  final bool isStaff;
  final UserProfile? profile;
  final UserLoyaltyStats? loyaltyStats;

  ApiUser({
    required this.id,
    required this.email,
    required this.username,
    required this.isMerchant,
    required this.isCustomer,
    this.isAdmin = false,
    this.isSuperuser = false,
    this.isStaff = false,
    this.profile,
    this.loyaltyStats,
  });

  ApiUser copyWith({
    int? id,
    String? email,
    String? username,
    bool? isMerchant,
    bool? isCustomer,
    bool? isAdmin,
    bool? isSuperuser,
    bool? isStaff,
    UserProfile? profile,
    UserLoyaltyStats? loyaltyStats,
  }) {
    return ApiUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      isMerchant: isMerchant ?? this.isMerchant,
      isCustomer: isCustomer ?? this.isCustomer,
      isAdmin: isAdmin ?? this.isAdmin,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      isStaff: isStaff ?? this.isStaff,
      profile: profile ?? this.profile,
      loyaltyStats: loyaltyStats ?? this.loyaltyStats,
    );
  }

  /// Convenience getter for profile picture
  String? get profilePicture => profile?.profilePicture.urlFor(fullScreen: false);

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? (json['profile'] != null && json['profile'] is Map ? json['profile']['role'] as String? : null);
    final isAdminVal = json['is_admin'] as bool? ?? (roleStr == 'admin' || json['is_superuser'] == true);

    return ApiUser(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      isMerchant: json['is_merchant'] as bool? ?? false,
      isCustomer: json['is_customer'] as bool? ?? true,
      isAdmin: isAdminVal,
      isSuperuser: json['is_superuser'] as bool? ?? false,
      isStaff: json['is_staff'] as bool? ?? false,
      profile:
          json['profile'] != null && json['profile'] is Map<String, dynamic>
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      loyaltyStats: json['loyalty_stats'] != null
          ? UserLoyaltyStats.fromJson(json['loyalty_stats'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isMysteryGuest {
    return profile?.role == UserProfile.roleMysteryGuest;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'is_merchant': isMerchant,
      'is_customer': isCustomer,
      'is_admin': isAdmin,
      'is_superuser': isSuperuser,
      'is_staff': isStaff,
      'profile': profile?.toJson(),
      if (loyaltyStats != null) 'loyalty_stats': loyaltyStats!.toJson(),
    };
  }
}

/// User Profile model
class UserProfile {
  static const String roleAdmin = 'admin';
  static const String roleMerchant = 'merchant';
  static const String roleCustomer = 'customer';
  static const String roleMysteryGuest = 'mystery_guest';

  final String role;
  final String? phoneNumber;
  final ImageVariants profilePicture;
  final bool marketingOptIn;

  UserProfile({
    required this.role,
    this.phoneNumber,
    this.profilePicture = const ImageVariants(),
    this.marketingOptIn = true,
  });

  UserProfile copyWith({
    String? role,
    String? phoneNumber,
    ImageVariants? profilePicture,
    bool? marketingOptIn,
  }) {
    return UserProfile(
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawProfilePicture = json['profile_picture'];
    ImageVariants parsedProfilePic;
    if (rawProfilePicture is Map<String, dynamic>) {
      parsedProfilePic = ImageVariants.fromJson(rawProfilePicture);
    } else if (rawProfilePicture is String) {
      parsedProfilePic = ImageVariants(medium: rawProfilePicture, large: rawProfilePicture);
    } else {
      parsedProfilePic = const ImageVariants();
    }

    return UserProfile(
      role: json['role'] as String? ?? 'customer',
      phoneNumber: json['phone_number'] as String?,
      profilePicture: parsedProfilePic,
      marketingOptIn: json['marketing_opt_in'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture.toJson(),
      'marketing_opt_in': marketingOptIn,
    };
  }
}

/// Login Response model
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String username;
  final String role; // 'customer', 'merchant', 'admin'
  final bool isAdmin;
  final bool isSuperuser;
  final bool isStaff;
  final ApiUser? user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.username,
    required this.role,
    this.isAdmin = false,
    this.isSuperuser = false,
    this.isStaff = false,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Extract role from response
    final role = json['role'] as String? ?? 'customer';
    final username = json['username'] as String? ?? '';
    final isAdmin = json['is_admin'] == true || role == 'admin' || json['is_superuser'] == true;
    final isSuperuser = json['is_superuser'] == true;
    final isStaff = json['is_staff'] == true;

    // Handle case where 'user' might be null or missing
    ApiUser? user;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      user = ApiUser.fromJson(json['user'] as Map<String, dynamic>);
    } else {
      // Construct user from available fields
      final isMerchant = role == 'merchant' || json['is_merchant'] == true;
      final isCustomer = role == 'customer' || json['is_customer'] == true;

      user = ApiUser(
        id: json['id'] as int? ?? 0,
        email: json['email'] as String? ?? '',
        username: username,
        isMerchant: isMerchant,
        isCustomer: isCustomer,
        isAdmin: isAdmin,
        isSuperuser: isSuperuser,
        isStaff: isStaff,
        profile: UserProfile(
          role: role,
          phoneNumber: json['phone_number'] as String?,
          marketingOptIn: json['marketing_opt_in'] as bool? ?? true,
        ),
      );
    }

    return LoginResponse(
      accessToken:
          json['access'] as String? ?? json['access_token'] as String? ?? '',
      refreshToken:
          json['refresh'] as String? ?? json['refresh_token'] as String? ?? '',
      username: username,
      role: role,
      isAdmin: isAdmin,
      isSuperuser: isSuperuser,
      isStaff: isStaff,
      user: user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': accessToken,
      'refresh': refreshToken,
      'username': username,
      'role': role,
      'is_admin': isAdmin,
      'is_superuser': isSuperuser,
      'is_staff': isStaff,
      'user': user?.toJson(),
    };
  }
}

/// Register Response model
class RegisterResponse {
  final int id;
  final String email;
  final String username;
  final String role;

  RegisterResponse({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    String role = 'customer';
    if (json['role'] != null) {
      role = json['role'] as String;
    } else if (json['profile'] != null &&
        json['profile'] is Map<String, dynamic> &&
        json['profile']['role'] != null) {
      role = json['profile']['role'] as String;
    }

    return RegisterResponse(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'username': username, 'role': role};
  }
}
