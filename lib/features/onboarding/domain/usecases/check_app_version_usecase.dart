import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:discount_buddy/features/onboarding/models/app_version_info.dart';

/// Check app version
class CheckAppVersionUseCase {
  CheckAppVersionUseCase(this._repository);
  final OnboardingRepository _repository;

  Future<Result<AppVersionInfo?>> call() => _repository.checkAppVersion();
}
