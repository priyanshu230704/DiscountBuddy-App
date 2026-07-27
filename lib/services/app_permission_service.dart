import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'location_service.dart';

/// Coordinates startup permission prompts so iOS shows one dialog at a time.
class AppPermissionService {
  static final AppPermissionService _instance = AppPermissionService._internal();
  factory AppPermissionService() => _instance;
  AppPermissionService._internal();

  final LocationService _locationService = LocationService();
  bool _locationPromptAttempted = false;
  final Completer<void> _startupLocationCompleter = Completer<void>();

  /// Home and other screens should await this before requesting location on first launch.
  Future<void> waitForStartupLocationPrompt() => _startupLocationCompleter.future;

  /// Call after notification permission has finished (e.g. Firebase Messaging init).
  Future<void> requestLocationAfterNotifications() async {
    if (_locationPromptAttempted) return;
    _locationPromptAttempted = true;

    try {
      final current = await _locationService.checkPermission();
      if (!LocationService.canRequestPermission(current)) return;

      // iOS only shows one system dialog at a time; wait for the prior one to dismiss.
      if (!kIsWeb && Platform.isIOS) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      final result = await _locationService.requestPermission();
      debugPrint('📍 Location permission result: $result');
    } catch (e) {
      debugPrint('📍 Location permission request failed: $e');
    } finally {
      if (!_startupLocationCompleter.isCompleted) {
        _startupLocationCompleter.complete();
      }
    }
  }
}
