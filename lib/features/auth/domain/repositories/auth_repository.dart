import 'dart:io';

import 'package:discount_buddy/features/auth/domain/entities/auth_session.dart';
import 'package:discount_buddy/features/auth/domain/entities/user_entity.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

/// Intent-based auth contract — not a mirror of AuthService.
abstract class AuthRepository {
  Future<Result<AuthSession>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AuthSession>> loginWithSocial({
    required SocialProvider provider,
  });

  Future<Result<void>> startRegistration({
    required String email,
    required String role,
  });

  Future<Result<void>> verifyRegistrationOtp({
    required String email,
    required String otp,
  });

  Future<Result<OtpResendInfo>> resendRegistrationOtp({
    required String email,
  });

  /// Creates the account then establishes a session (login).
  Future<Result<AuthSession>> completeRegistration({
    required String email,
    required String otp,
    required String password,
    String? username,
  });

  /// Legacy single-shot register + session.
  Future<Result<AuthSession>> registerWithPassword({
    required String email,
    required String username,
    required String password,
    required String role,
  });

  Future<Result<UsernameAvailability>> checkUsername(String username);

  /// Load stored access token into the HTTP client; true if a token exists.
  Future<Result<bool>> hasCredentials();

  /// Load token into HTTP client + optional cached user (no network).
  Future<Result<AuthSession?>> restoreSession();

  /// Refresh access token; returns session from cache/network if possible.
  Future<Result<AuthSession>> refreshSession();

  Future<Result<UserEntity>> fetchCurrentUser();

  Future<Result<UserEntity?>> readCachedUser();

  Future<Result<void>> logoutRemote();

  Future<Result<void>> clearLocalSession();

  Future<Result<void>> requestPasswordResetOtp({required String email});

  Future<Result<void>> verifyPasswordResetOtp({
    required String email,
    required String otp,
  });

  Future<Result<void>> confirmPasswordReset({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  });

  Future<Result<void>> requestPasswordResetEmail({required String email});

  Future<Result<UserEntity>> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    File? imageFile,
    String? avatarUrl,
  });

  Future<Result<void>> deleteAccountInit();

  Future<Result<void>> deleteAccount({required String otp});
}
