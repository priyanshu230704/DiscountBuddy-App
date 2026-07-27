import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class VerifyRegistrationOtpUseCase {
  VerifyRegistrationOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required String otp,
  }) {
    return _repository.verifyRegistrationOtp(email: email, otp: otp);
  }
}
