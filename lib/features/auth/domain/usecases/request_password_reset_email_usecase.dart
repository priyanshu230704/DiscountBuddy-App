import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class RequestPasswordResetEmailUseCase {
  RequestPasswordResetEmailUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) {
    return _repository.requestPasswordResetEmail(email: email);
  }
}
