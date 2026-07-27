import 'package:discount_buddy/features/auth/domain/ports/device_token_port.dart';
import 'package:discount_buddy/features/notifications/data/firebase_messaging_service.dart';
import 'package:flutter/foundation.dart';

class DeviceTokenAdapter implements DeviceTokenPort {
  DeviceTokenAdapter({FirebaseMessagingService? messaging})
      : _messaging = messaging ?? FirebaseMessagingService();

  final FirebaseMessagingService _messaging;

  @override
  Future<void> registerAfterLogin() async {
    try {
      await _messaging.registerTokenAfterLogin();
    } catch (e) {
      debugPrint('DeviceTokenAdapter.registerAfterLogin: $e');
    }
  }

  @override
  Future<void> deactivateCurrentDevice() async {
    try {
      await _messaging.deactivateCurrentDevice();
    } catch (e) {
      debugPrint('DeviceTokenAdapter.deactivateCurrentDevice: $e');
    }
  }
}
