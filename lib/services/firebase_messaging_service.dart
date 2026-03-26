import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'auth_service.dart';
import '../utils/navigator_key.dart';
import 'package:flutter/material.dart';

/// Service to handle Firebase Cloud Messaging
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging and request permissions
  Future<void> initialize() async {
    // Request permission (mainly for iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Handle foreground notifications (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
      await _getFCMToken();
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ User granted provisional notification permission');
      await _getFCMToken();
    } else {
      debugPrint('❌ User declined notification permission');
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // 📩 Handle notification tapped when app is in BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    // 📩 Handle notification if app is launched FROM TERMINATED STATE
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpen(initialMessage);
    }
  }

  /// Handle navigation when a notification is tapped
  void _handleMessageOpen(RemoteMessage message) {
    debugPrint('📩 Notification Tapped: ${message.data}');
    
    final type = message.data['type'] ?? '';
    _navigateToCorrectScreen(type, message.data);
  }

  /// Navigates to the appropriate screen based on notification type
  void _navigateToCorrectScreen(String type, Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    NotificationService.handleNotificationNavigation(context, type, data);
  }

  /// Get FCM token and register with backend
  Future<void> _getFCMToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _messaging.getAPNSToken();
        debugPrint('🍎 APNS Token: $apnsToken');
      }
      
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('==============================================');
        debugPrint('📱 FCM Token: $_fcmToken');
        debugPrint('==============================================');
        await _registerTokenWithBackend(_fcmToken!);
      }
    } catch (e) {
      debugPrint('❌ Error getting tokens: $e');
    }
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      // Only register if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        await _notificationService.registerDeviceToken(
          token: token,
          deviceType: defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        );
        debugPrint('✅ FCM token registered with backend');
      } else {
        debugPrint('⚠️ User not logged in, skipping token registration');
      }
    } catch (e) {
      debugPrint('❌ Error registering FCM token with backend: $e');
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('🔄 FCM token refreshed: $newToken');
    _fcmToken = newToken;
    await _registerTokenWithBackend(newToken);
  }

  /// Register token after user login
  Future<void> registerTokenAfterLogin() async {
    if (_fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
    } else {
      await _getFCMToken();
    }
  }

  /// Deactivate token on logout
  Future<void> deactivateTokenOnLogout(String tokenId) async {
    try {
      await _notificationService.deactivateDeviceToken(tokenId);
      debugPrint('✅ FCM token deactivated on logout');
    } catch (e) {
      debugPrint('❌ Error deactivating FCM token: $e');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _messaging.getNotificationSettings();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
