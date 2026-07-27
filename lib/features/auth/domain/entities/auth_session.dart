import 'package:discount_buddy/features/auth/domain/entities/user_entity.dart';

class AuthSession {
  final UserEntity user;
  final String role;
  final bool isAuthenticated;

  const AuthSession({
    required this.user,
    required this.role,
    this.isAuthenticated = true,
  });
}

class UsernameAvailability {
  final bool available;
  final String? message;
  final Map<String, dynamic> raw;

  const UsernameAvailability({
    required this.available,
    this.message,
    this.raw = const {},
  });

  Map<String, dynamic> toLegacyMap() => {
        ...raw,
        'available': available,
        if (message != null) 'message': message,
      };
}

class OtpResendInfo {
  final bool success;
  final String? detail;
  final int? remainingMinutes;
  final Map<String, dynamic> raw;

  const OtpResendInfo({
    required this.success,
    this.detail,
    this.remainingMinutes,
    this.raw = const {},
  });

  Map<String, dynamic> toLegacyMap() => {
        ...raw,
        'success': success,
        if (detail != null) 'detail': detail,
        if (remainingMinutes != null) 'remaining_minutes': remainingMinutes,
      };
}

enum SocialProvider { google, apple }
