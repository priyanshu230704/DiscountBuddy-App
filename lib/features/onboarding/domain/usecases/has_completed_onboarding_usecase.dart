import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Check if user has completed onboarding
class HasCompletedOnboardingUseCase {
  HasCompletedOnboardingUseCase(this._repository);
  final OnboardingRepository _repository;

  Future<Result<bool>> call() => _repository.hasCompletedOnboarding();
}
