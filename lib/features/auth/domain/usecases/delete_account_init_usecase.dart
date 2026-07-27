import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class DeleteAccountInitUseCase {
  DeleteAccountInitUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.deleteAccountInit();
}
