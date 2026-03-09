import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version_info.dart';
import 'api_service.dart';

class AppConfigService {
  final ApiService _apiService = ApiService();

  Future<AppVersionInfo?> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final platform = Platform.isAndroid ? 'android' : 'ios';

      debugPrint(
        'APP_VERSION_CHECK: Requesting for $platform version $currentVersion',
      );

      final response = await _apiService.post(
        '/app/version/check/', // Match Django trailing slash pattern
        body: {'platform': platform, 'version': currentVersion},
        type: ApiType.common,
      );

      debugPrint('APP_VERSION_CHECK: Response received: $response');

      return AppVersionInfo.fromJson(response);
    } catch (e) {
      debugPrint('APP_VERSION_CHECK: Error checking version: $e');
      // In production, you might want to log this to a crash reporting tool
      // For now, we'll just fail silently to not block app startup
      return null;
    }
  }
}
