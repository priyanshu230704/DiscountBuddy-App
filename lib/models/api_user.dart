/// API User model matching the API response structure
class ApiUser {
  final int id;
  final String email;
  final String username;
  final bool isMerchant;
  final bool isCustomer;
  final UserProfile? profile;

  ApiUser({
    required this.id,
    required this.email,
    required this.username,
    required this.isMerchant,
    required this.isCustomer,
    this.profile,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      isMerchant: json['is_merchant'] as bool? ?? false,
      isCustomer: json['is_customer'] as bool? ?? true,
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'is_merchant': isMerchant,
      'is_customer': isCustomer,
      'profile': profile?.toJson(),
    };
  }
}

/// User Profile model
class UserProfile {
  final String role;
  final String? phoneNumber;
  final bool marketingOptIn;

  UserProfile({
    required this.role,
    this.phoneNumber,
    this.marketingOptIn = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      role: json['role'] as String,
      phoneNumber: json['phone_number'] as String?,
      marketingOptIn: json['marketing_opt_in'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'phone_number': phoneNumber,
      'marketing_opt_in': marketingOptIn,
    };
  }
}

/// Login Response model
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final ApiUser user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
      user: ApiUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': accessToken,
      'refresh': refreshToken,
      'user': user.toJson(),
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
    return RegisterResponse(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role,
    };
  }
}
