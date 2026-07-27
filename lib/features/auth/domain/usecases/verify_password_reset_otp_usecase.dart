import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class VerifyPasswordResetOtpUseCase {
  VerifyPasswordResetOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required String otp,
  }) {
    return _repository.verifyPasswordResetOtp(email: email, otp: otp);
  }
}
