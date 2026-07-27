import 'package:discount_buddy/features/auth/domain/entities/auth_session.dart';
import 'package:discount_buddy/features/auth/domain/entities/user_entity.dart';
import 'package:discount_buddy/features/auth/domain/failures/auth_failure.dart';
import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';
import 'package:discount_buddy/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:flutter/foundation.dart';

/// Cold-start: hasCredentials → getCurrentUser → refreshToken if needed → clear if empty.
class InitializeSessionUseCase {
  InitializeSessionUseCase(
    this._repository,
    this._refreshToken,
    this._getCurrentUser,
  );

  final AuthRepository _repository;
  final RefreshTokenUseCase _refreshToken;
  final GetCurrentUserUseCase _getCurrentUser;

  Future<Result<AuthSession?>> call() async {
    try {
      final creds = await _repository.hasCredentials();
      if (creds is Err<bool>) {
        return Err(creds.failure);
      }
      if (creds is Success<bool> && !creds.value) {
        return const Success(null);
      }

      final userResult = await _getCurrentUser();
      if (userResult is Success<UserEntity?> && userResult.value != null) {
        final user = userResult.value!;
        return Success(
          AuthSession(user: user, role: user.role, isAuthenticated: true),
        );
      }

      if (userResult is Err<UserEntity?> &&
          userResult.failure is UnauthorizedFailure) {
        return const Success(null);
      }

      final refreshed = await _refreshToken();
      if (refreshed is Success<AuthSession>) {
        return Success(refreshed.value);
      }

      debugPrint(
        'InitializeSessionUseCase: no user after restore/refresh — clearing',
      );
      await _repository.clearLocalSession();
      return const Success(null);
    } catch (e) {
      debugPrint('InitializeSessionUseCase ERROR: $e');
      await _repository.clearLocalSession();
      return const Success(null);
    }
  }
}
