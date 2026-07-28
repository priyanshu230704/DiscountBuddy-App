import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Reset onboarding
class ResetOnboardingUseCase {
  ResetOnboardingUseCase(this._repository);
  final OnboardingRepository _repository;

  Future<Result<void>> call() => _repository.resetOnboarding();
}
