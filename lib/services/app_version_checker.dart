import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/app_version_info.dart';
import '../routes/app_routes.dart';
import '../utils/navigator_key.dart';
import '../widgets/optional_update_sheet.dart';
import 'app_config_service.dart';

/// Version check runs once at cold start (splash), not on resume or polling.
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
