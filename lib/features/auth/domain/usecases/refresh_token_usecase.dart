import 'package:discount_buddy/features/auth/domain/entities/auth_session.dart';
import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class RefreshTokenUseCase {
  RefreshTokenUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<AuthSession>> call() => _repository.refreshSession();
}
