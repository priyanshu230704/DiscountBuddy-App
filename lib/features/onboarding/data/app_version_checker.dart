import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:discount_buddy/features/onboarding/models/app_version_info.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'package:discount_buddy/core/utils/navigator_key.dart';
import 'package:discount_buddy/features/onboarding/widgets/optional_update_sheet.dart';
import 'package:discount_buddy/core/device/app_config_service.dart';

/// Version checks at startup and on resume.
///
/// - **Force / critical** → full-screen [AppUpdatePage]
/// - **Optional** → popup once per app session (resets on cold start)
class AppVersionChecker {
  static bool _isShowingUpdatePage = false;
  static bool _optionalUpdateShownThisSession = false;
  static AppVersionInfo? _pendingOptionalUpdate;
  static bool _isChecking = false;

  /// Startup check from splash. Returns `true` if force update blocks navigation.
  static Future<bool> checkAtStartup() async {
    if (_isShowingUpdatePage || _isChecking) return true;
    
    _isChecking = true;
    try {
      final versionInfo = await AppConfigService().checkVersion();
      if (versionInfo == null || !versionInfo.isUpdateAvailable) {
        return false;
      }

      if (_isForceOrCritical(versionInfo)) {
        return _navigateToForceUpdatePage(versionInfo);
      }

      if (!_optionalUpdateShownThisSession) {
        _pendingOptionalUpdate = versionInfo;
      }
      return false;
    } catch (e) {
      debugPrint('APP_VERSION_CHECK: Startup error: $e');
      _isShowingUpdatePage = false;
      return false;
    } finally {
      _isChecking = false;
    }
  }

  /// Shows optional-update bottom sheet once per session, after splash navigates away.
  static void showOptionalUpdateSheetOnce() {
    if (_optionalUpdateShownThisSession || _pendingOptionalUpdate == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_optionalUpdateShownThisSession || _pendingOptionalUpdate == null) {
        return;
      }

      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      final versionInfo = _pendingOptionalUpdate!;
      _optionalUpdateShownThisSession = true;
      _pendingOptionalUpdate = null;

      await OptionalUpdateSheet.show(context, versionInfo);
    });
  }

  /// Re-run on app resume — force/critical only (not optional popup again).
  static Future<void> checkOnResume({String continueRoute = AppRoutes.home}) async {
    if (_isShowingUpdatePage || _isChecking) return;

    _isChecking = true;
    try {
      final versionInfo = await AppConfigService().checkVersion();
      if (versionInfo == null || !versionInfo.isUpdateAvailable) return;
      if (!_isForceOrCritical(versionInfo)) return;

      _navigateToForceUpdatePage(versionInfo, continueRoute: continueRoute);
    } catch (e) {
      debugPrint('APP_VERSION_CHECK: Resume error: $e');
      _isShowingUpdatePage = false;
    } finally {
      _isChecking = false;
    }
  }

  static bool _isForceOrCritical(AppVersionInfo info) =>
      info.isForceUpdate || info.isCriticalUpdate;

  static bool _navigateToForceUpdatePage(
    AppVersionInfo versionInfo, {
    String continueRoute = AppRoutes.onboardingCheck,
  }) {
    if (Get.key.currentState == null) return false;

    _isShowingUpdatePage = true;
    _pendingOptionalUpdate = null;

    Get.offAllNamed(
      AppRoutes.appUpdate,
      arguments: {
        'versionInfo': versionInfo,
        'continueRoute': continueRoute,
      },
    );
    return true;
  }

  static void resetShowingFlag() {
    _isShowingUpdatePage = false;
  }

  @Deprecated('Use checkAtStartup')
  static Future<bool> checkAndNavigate({
    String continueRoute = '/onboarding-check',
  }) =>
      checkAtStartup();
}
