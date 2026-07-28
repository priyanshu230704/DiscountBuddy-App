import 'package:flutter/foundation.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/features/onboarding/data/onboarding_repository_impl.dart';
import 'package:discount_buddy/features/onboarding/domain/usecases/check_app_version_usecase.dart';
import 'package:discount_buddy/features/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:discount_buddy/features/onboarding/domain/usecases/has_completed_onboarding_usecase.dart';
import 'package:discount_buddy/features/onboarding/domain/usecases/reset_onboarding_usecase.dart';
import 'package:discount_buddy/features/onboarding/models/app_version_info.dart';

/// Presentation state for onboarding
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider() {
    final repo = OnboardingRepositoryImpl();

    _hasCompletedOnboardingUseCase = HasCompletedOnboardingUseCase(repo);
    _completeOnboardingUseCase = CompleteOnboardingUseCase(repo);
    _resetOnboardingUseCase = ResetOnboardingUseCase(repo);
    _checkAppVersionUseCase = CheckAppVersionUseCase(repo);
  }

  late HasCompletedOnboardingUseCase _hasCompletedOnboardingUseCase;
  late CompleteOnboardingUseCase _completeOnboardingUseCase;
  late ResetOnboardingUseCase _resetOnboardingUseCase;
  late CheckAppVersionUseCase _checkAppVersionUseCase;

  bool _hasCompletedOnboarding = false;
  AppVersionInfo? _appVersionInfo;
  Failure? _error;
  bool _isLoading = false;

  // Getters
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  AppVersionInfo? get appVersionInfo => _appVersionInfo;
  Failure? get error => _error;
  bool get isLoading => _isLoading;

  /// Check if onboarding is completed
  Future<void> checkHasCompletedOnboarding() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _hasCompletedOnboardingUseCase();

    result.fold(
      onSuccess: (completed) {
        _hasCompletedOnboarding = completed;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _hasCompletedOnboarding = false;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _completeOnboardingUseCase();

    result.fold(
      onSuccess: (_) {
        _hasCompletedOnboarding = true;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Reset onboarding
  Future<void> resetOnboarding() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _resetOnboardingUseCase();

    result.fold(
      onSuccess: (_) {
        _hasCompletedOnboarding = false;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Check app version
  Future<void> checkAppVersion() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _checkAppVersionUseCase();

    result.fold(
      onSuccess: (versionInfo) {
        _appVersionInfo = versionInfo;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _appVersionInfo = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Clear all state
  void clear() {
    _hasCompletedOnboarding = false;
    _appVersionInfo = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
