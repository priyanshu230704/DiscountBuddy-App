import 'package:discount_buddy/features/auth/domain/entities/user_entity.dart';
import 'package:discount_buddy/features/auth/domain/failures/auth_failure.dart';
import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

/// Fetches current user; falls back to cache. On unauthorized, clears local session.
class GetCurrentUserUseCase {
  GetCurrentUserUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<UserEntity?>> call() async {
    final remote = await _repository.fetchCurrentUser();
    if (remote is Success<UserEntity>) {
      return Success(remote.value);
    }

    if (remote is Err<UserEntity> && remote.failure is UnauthorizedFailure) {
      await _repository.clearLocalSession();
      return Err(remote.failure);
    }

    final cached = await _repository.readCachedUser();
    if (cached is Success<UserEntity?> && cached.value != null) {
      return Success(cached.value);
    }

    if (remote is Err<UserEntity>) {
      return Err(remote.failure);
    }
    return const Success(null);
  }
}
