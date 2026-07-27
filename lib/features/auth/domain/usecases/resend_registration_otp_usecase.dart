import 'package:discount_buddy/features/auth/domain/entities/auth_session.dart';
import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class ResendRegistrationOtpUseCase {
  ResendRegistrationOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<OtpResendInfo>> call({required String email}) {
    return _repository.resendRegistrationOtp(email: email);
  }
}
