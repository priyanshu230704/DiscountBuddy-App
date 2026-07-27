import 'package:discount_buddy/features/auth/domain/entities/auth_session.dart';
import 'package:discount_buddy/features/auth/domain/ports/device_token_port.dart';
import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';
import 'package:discount_buddy/features/auth/domain/usecases/get_current_user_usecase.dart';

class CompleteRegistrationUseCase {
  CompleteRegistrationUseCase(
    this._repository,
    this._tokens, {
    GetCurrentUserUseCase? getCurrentUser,
  }) : _getCurrentUser = getCurrentUser;

  final AuthRepository _repository;
  final DeviceTokenPort _tokens;
  final GetCurrentUserUseCase? _getCurrentUser;

  Future<Result<AuthSession>> call({
    required String email,
    required String otp,
    required String password,
    String? username,
  }) async {
    final result = await _repository.completeRegistration(
      email: email,
      otp: otp,
      password: password,
      username: username,
    );
    if (result is! Success<AuthSession>) return result;

    await _tokens.registerAfterLogin();

    final refresh = _getCurrentUser;
    if (refresh != null) {
      final user = (await refresh()).valueOrNull;
      if (user != null) {
        return Success(
          AuthSession(user: user, role: user.role, isAuthenticated: true),
        );
      }
    }
    return result;
  }
}
