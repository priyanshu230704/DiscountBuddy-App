import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/onboarding/models/app_version_info.dart';

/// Intent-based onboarding repository
abstract class OnboardingRepository {
  /// Check if user has completed onboarding
  Future<Result<bool>> hasCompletedOnboarding();

  /// Mark onboarding as completed
  Future<Result<void>> completeOnboarding();

  /// Reset onboarding (for testing)
  Future<Result<void>> resetOnboarding();

  /// Check app version for updates
  Future<Result<AppVersionInfo?>> checkAppVersion();
}
