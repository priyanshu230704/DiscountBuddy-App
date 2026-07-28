import 'dart:io';

import 'package:discount_buddy/core/domain/error_mapper.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/core/domain/failures/network_failure.dart';
import 'package:discount_buddy/core/network/api_service.dart';
import 'package:discount_buddy/features/auth/data/auth_service.dart';
import 'package:discount_buddy/features/auth/data/mappers/user_mapper.dart';
import 'package:discount_buddy/features/auth/domain/entities/auth_session.dart';
import 'package:discount_buddy/features/auth/domain/entities/user_entity.dart';
import 'package:discount_buddy/features/auth/domain/failures/auth_failure.dart';
import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';
import 'package:discount_buddy/features/auth/models/api_user.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthService? authService, UserMapper? mapper})
    : _service = authService ?? AuthService(),
      _mapper = mapper ?? const UserMapper();

  final AuthService _service;
  final UserMapper _mapper;

  Failure _mapError(Object e, {String fallback = 'Something went wrong'}) =>
      mapToFailure(e, fallback: fallback);

  AuthSession _sessionFromLogin(LoginResponse response) {
    final dto = response.user;
    if (dto == null) {
      throw ApiException('Login succeeded but user payload was missing');
    }
    final entity = _mapper.toEntity(dto, roleOverride: response.role);
    return AuthSession(user: entity, role: response.role);
  }

  AuthSession _sessionFromUser(ApiUser dto, {String? roleOverride}) {
    final entity = _mapper.toEntity(dto, roleOverride: roleOverride);
    return AuthSession(user: entity, role: entity.role);
  }

  @override
  Future<Result<AuthSession>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _service.login(email: email, password: password);
      return Success(_sessionFromLogin(response));
    } catch (e) {
      return Err(_mapError(e, fallback: 'Login failed'));
    }
  }

  @override
  Future<Result<AuthSession>> loginWithSocial({
    required SocialProvider provider,
  }) async {
    try {
      final LoginResponse response = switch (provider) {
        SocialProvider.google => await _service.loginWithGoogle(),
        SocialProvider.apple => await _service.loginWithApple(),
      };
      return Success(_sessionFromLogin(response));
    } catch (e) {
      return Err(_mapError(e, fallback: 'Social login failed'));
    }
  }

  @override
  Future<Result<void>> startRegistration({
    required String email,
    required String role,
  }) async {
    try {
      await _service.registerInit(email: email, role: role);
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not start registration'));
    }
  }

  @override
  Future<Result<void>> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _service.verifyOtp(email: email, otp: otp);
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'OTP verification failed'));
    }
  }

  @override
  Future<Result<OtpResendInfo>> resendRegistrationOtp({
    required String email,
  }) async {
    try {
      final raw = await _service.resendOtp(email: email);
      final success = raw['success'] == true;
      return Success(
        OtpResendInfo(
          success: success,
          detail: raw['detail']?.toString(),
          remainingMinutes: raw['remaining_minutes'] is int
              ? raw['remaining_minutes'] as int
              : int.tryParse('${raw['remaining_minutes']}'),
          raw: raw,
        ),
      );
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not resend OTP'));
    }
  }

  @override
  Future<Result<AuthSession>> completeRegistration({
    required String email,
    required String otp,
    required String password,
    String? username,
  }) async {
    try {
      await _service.registerComplete(
        email: email,
        otp: otp,
        password: password,
        username: username,
      );
      return loginWithEmail(email: email, password: password);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Registration failed'));
    }
  }

  @override
  Future<Result<AuthSession>> registerWithPassword({
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      await _service.register(
        email: email,
        username: username,
        password: password,
        role: role,
      );
      return loginWithEmail(email: email, password: password);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Registration failed'));
    }
  }

  @override
  Future<Result<UsernameAvailability>> checkUsername(String username) async {
    try {
      final raw = await _service.checkUsernameAvailability(username);
      final available = raw['available'] == true;
      return Success(
        UsernameAvailability(
          available: available,
          message:
              raw['message']?.toString() ??
              raw['error']?.toString() ??
              raw['detail']?.toString(),
          raw: raw,
        ),
      );
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not check username'));
    }
  }

  @override
  Future<Result<bool>> hasCredentials() async {
    try {
      await _service.initializeAuth();
      return Success(await _service.isLoggedIn());
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to check credentials'));
    }
  }

  @override
  Future<Result<AuthSession?>> restoreSession() async {
    try {
      await _service.initializeAuth();
      final loggedIn = await _service.isLoggedIn();
      if (!loggedIn) return const Success(null);
      final cached = await _service.getStoredUser();
      if (cached == null) return const Success(null);
      return Success(_sessionFromUser(cached));
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to restore session'));
    }
  }

  @override
  Future<Result<AuthSession>> refreshSession() async {
    try {
      final ok = await _service.refreshAccessToken();
      if (!ok) {
        return const Err(UnauthorizedFailure('Could not refresh session'));
      }
      final user =
          await _service.getCurrentUser() ?? await _service.getStoredUser();
      if (user == null) {
        return const Err(AuthFailure('Session refreshed but user missing'));
      }
      return Success(_sessionFromUser(user));
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not refresh session'));
    }
  }

  @override
  Future<Result<UserEntity>> fetchCurrentUser() async {
    try {
      final user = await _service.getCurrentUser();
      if (user == null) {
        return const Err(NetworkFailure('Could not load current user'));
      }
      return Success(_mapper.toEntity(user));
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not load current user'));
    }
  }

  @override
  Future<Result<UserEntity?>> readCachedUser() async {
    try {
      final user = await _service.getStoredUser();
      return Success(user == null ? null : _mapper.toEntity(user));
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not read cached user'));
    }
  }

  @override
  Future<Result<void>> logoutRemote() async {
    try {
      await _service.postLogoutToServer();
      return const Success(null);
    } catch (e) {
      // Remote logout is best-effort
      return const Success(null);
    }
  }

  @override
  Future<Result<void>> clearLocalSession() async {
    try {
      await _service.wipeLocalSessionAfterLogout();
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not clear local session'));
    }
  }

  @override
  Future<Result<void>> requestPasswordResetOtp({required String email}) async {
    try {
      await _service.requestPasswordResetOtp(email: email);
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not request reset OTP'));
    }
  }

  @override
  Future<Result<void>> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _service.verifyPasswordResetOtp(email: email, otp: otp);
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'OTP verification failed'));
    }
  }

  @override
  Future<Result<void>> confirmPasswordReset({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _service.confirmPasswordReset(
        email: email,
        otp: otp,
        password: password,
        confirmPassword: confirmPassword,
      );
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not reset password'));
    }
  }

  @override
  Future<Result<void>> requestPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _service.passwordReset(email: email);
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not send reset email'));
    }
  }

  @override
  Future<Result<UserEntity>> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    File? imageFile,
    String? avatarUrl,
  }) async {
    try {
      final updated = await _service.updateProfile(
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        imageFile: imageFile,
        avatarUrl: avatarUrl,
      );
      var entity = _mapper.toEntity(updated);
      if (avatarUrl != null) {
        entity = entity.copyWith(profilePictureUrl: avatarUrl);
      }
      return Success(entity);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not update profile'));
    }
  }

  @override
  Future<Result<void>> deleteAccountInit() async {
    try {
      await _service.initDeleteAccount();
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not start account deletion'));
    }
  }

  @override
  Future<Result<void>> deleteAccount({required String otp}) async {
    try {
      await _service.deleteAccount(otp: otp);
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Could not delete account'));
    }
  }
}
