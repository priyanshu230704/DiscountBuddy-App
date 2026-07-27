import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const String _kPrefsDeviceIdKey = 'discount_buddy_app_device_id';

/// Resolves a stable [device_id] for `POST /notifications/devices/`.
///
/// * **Android** — `Settings.Secure.ANDROID_ID` via [AndroidId] (per device+user+signing key).
/// * **iOS** — [IosDeviceInfo.identifierForVendor] (per team until all vendor apps are removed).
/// * **Web / emulators / missing native id** — a UUID in [SharedPreferences] (kept across logouts;
///   this file is not cleared by [AuthService] `deleteAll` on the secure store).
class DeviceIdService {
  DeviceIdService._();

  static String? _memory;
  static Future<String>? _inFlight;

  /// Opaque string safe to send as `device_id` on every FCM registration.
  static Future<String> getOrCreate() async {
    if (_memory != null && _memory!.isNotEmpty) return _memory!;

    _inFlight ??= _load().then((s) {
      _memory = s;
      return s;
    });
    try {
      return await _inFlight!;
    } catch (e) {
      _inFlight = null;
      rethrow;
    }
  }

  static Future<String> _load() async {
    if (kIsWeb) {
      return _prefsOrNewUuid();
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final id = await const AndroidId().getId();
      if (id != null && id.isNotEmpty) {
        return id;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final v = (await DeviceInfoPlugin().iosInfo).identifierForVendor;
      if (v != null && v.isNotEmpty) {
        return v;
      }
    }
    return _prefsOrNewUuid();
  }

  static Future<String> _prefsOrNewUuid() async {
    final p = await SharedPreferences.getInstance();
    var value = p.getString(_kPrefsDeviceIdKey);
    if (value == null || value.isEmpty) {
      value = const Uuid().v4();
      await p.setString(_kPrefsDeviceIdKey, value);
    }
    return value;
  }
}
