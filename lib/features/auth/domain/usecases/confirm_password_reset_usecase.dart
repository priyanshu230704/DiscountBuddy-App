import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class ConfirmPasswordResetUseCase {
  ConfirmPasswordResetUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) {
    return _repository.confirmPasswordReset(
      email: email,
      otp: otp,
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}
