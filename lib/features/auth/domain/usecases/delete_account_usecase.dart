import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class DeleteAccountUseCase {
  DeleteAccountUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({required String otp}) {
    return _repository.deleteAccount(otp: otp);
  }
}
