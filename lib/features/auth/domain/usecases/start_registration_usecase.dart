import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class StartRegistrationUseCase {
  StartRegistrationUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required String role,
  }) {
    return _repository.startRegistration(email: email, role: role);
  }
}
