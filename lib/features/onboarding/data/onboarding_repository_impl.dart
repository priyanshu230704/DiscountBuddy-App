import 'package:discount_buddy/core/device/app_config_service.dart';
import 'package:discount_buddy/core/domain/error_mapper.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/onboarding/data/onboarding_service.dart';
import 'package:discount_buddy/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:discount_buddy/features/onboarding/models/app_version_info.dart';

/// Implementation of OnboardingRepository
class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl({
    OnboardingService? onboardingService,
    AppConfigService? appConfigService,
  })  : _onboardingService = onboardingService ?? OnboardingService(),
        _appConfigService = appConfigService ?? AppConfigService();

  final OnboardingService _onboardingService;
  final AppConfigService _appConfigService;

  Failure _mapError(Object e, {String fallback = 'Something went wrong'}) =>
      mapToFailure(e, fallback: fallback);

  @override
  Future<Result<bool>> hasCompletedOnboarding() async {
    try {
      final completed = await _onboardingService.hasCompletedOnboarding();
      return Success(completed);
    } catch (e) {
      return Err(
        _mapError(e, fallback: 'Failed to check onboarding status'),
      );
    }
  }

  @override
  Future<Result<void>> completeOnboarding() async {
    try {
      await _onboardingService.completeOnboarding();
      return const Success(null);
    } catch (e) {
      return Err(
        _mapError(e, fallback: 'Failed to complete onboarding'),
      );
    }
  }

  @override
  Future<Result<void>> resetOnboarding() async {
    try {
      await _onboardingService.resetOnboarding();
      return const Success(null);
    } catch (e) {
      return Err(
        _mapError(e, fallback: 'Failed to reset onboarding'),
      );
    }
  }

  @override
  Future<Result<AppVersionInfo?>> checkAppVersion() async {
    try {
      final versionInfo = await _appConfigService.checkVersion();
      return Success(versionInfo);
    } catch (e) {
      return Err(
        _mapError(e, fallback: 'Failed to check app version'),
      );
    }
  }
}
