import 'package:discount_buddy/features/auth/domain/ports/device_token_port.dart';
import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class LogoutUseCase {
  LogoutUseCase(this._repository, this._tokens);

  final AuthRepository _repository;
  final DeviceTokenPort _tokens;

  Future<Result<void>> call() async {
    await Future.wait<void>([
      _tokens.deactivateCurrentDevice(),
      _repository.logoutRemote().then((_) {}),
    ]);
    return _repository.clearLocalSession();
  }
}
