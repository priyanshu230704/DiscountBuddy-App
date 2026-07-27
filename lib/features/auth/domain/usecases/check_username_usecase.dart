import 'package:discount_buddy/features/auth/domain/entities/auth_session.dart';
import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class CheckUsernameUseCase {
  CheckUsernameUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<UsernameAvailability>> call(String username) {
    return _repository.checkUsername(username);
  }
}
