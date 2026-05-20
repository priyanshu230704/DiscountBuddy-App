import 'package:flutter/material.dart';
import '../models/app_version_info.dart';
import '../pages/app_update_page.dart';
import '../utils/navigator_key.dart';
import '../widgets/optional_update_sheet.dart';
import 'app_config_service.dart';

/// Version checks at startup and on resume.
///
/// - **Force / critical** → full-screen [AppUpdatePage]
/// - **Optional** → popup once per app session (resets on cold start)
class AppVersionChecker {
  static bool _isShowingUpdatePage = false;
  static bool _optionalUpdateShownThisSession = false;
  static AppVersionInfo? _pendingOptionalUpdate;

  /// Startup check from splash. Returns `true` if force update blocks navigation.
  static Future<bool> checkAtStartup() async {
    if (_isShowingUpdatePage) return true;

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
  static Future<void> checkOnResume({String continueRoute = '/home'}) async {
    if (_isShowingUpdatePage) return;

    try {
      final versionInfo = await AppConfigService().checkVersion();
      if (versionInfo == null || !versionInfo.isUpdateAvailable) return;
      if (!_isForceOrCritical(versionInfo)) return;

      _navigateToForceUpdatePage(versionInfo, continueRoute: continueRoute);
    } catch (e) {
      debugPrint('APP_VERSION_CHECK: Resume error: $e');
      _isShowingUpdatePage = false;
    }
  }

  static bool _isForceOrCritical(AppVersionInfo info) =>
      info.isForceUpdate || info.isCriticalUpdate;

  static bool _navigateToForceUpdatePage(
    AppVersionInfo versionInfo, {
    String continueRoute = '/onboarding-check',
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return false;

    _isShowingUpdatePage = true;
    _pendingOptionalUpdate = null;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AppUpdatePage(
          versionInfo: versionInfo,
          continueRoute: continueRoute,
        ),
        settings: const RouteSettings(name: '/app-update'),
      ),
      (_) => false,
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
