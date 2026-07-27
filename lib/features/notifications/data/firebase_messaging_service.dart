import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:discount_buddy/features/notifications/data/notification_service.dart';
import 'package:discount_buddy/features/auth/data/auth_service.dart';
import 'package:discount_buddy/features/notifications/models/notification.dart';
import 'package:discount_buddy/features/notifications/data/notification_provider.dart';
import 'package:discount_buddy/core/utils/navigator_key.dart';

/// Service to handle Firebase Cloud Messaging
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Define the channel for Android 8+
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// FCM string last successfully sent to the backend; avoids double POST
  /// when [onTokenRefresh] and [registerTokenAfterLogin] race.
  String? _fcmSyncedWithBackend;

  /// Only one [register*] can run at a time so in-flight work serializes.
  Completer<void>? _registerInFlight;

  /// Initialize Firebase Messaging and request permissions
  Future<void> initialize() async {
    // 1. Initialize Local Notifications
    await _initializeLocalNotifications();

    // 2. Request permission (mainly for iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 3. Handle foreground notifications (iOS)
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

    // 4. Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // 📩 Handle notification tapped when app is in BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    // 📩 Handle notification if app is launched FROM TERMINATED STATE
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpen(initialMessage);
    }
  }

  /// Initialize local notifications for Android
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap
        if (response.payload != null) {
          // You could parse payload and navigate here if needed
          debugPrint('Local notification tapped with payload: ${response.payload}');
        }
      },
    );

    // Create the high importance channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Handle messages received while the app is in the FOREGROUND
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message received!');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    final RemoteNotification? notification = message.notification;
    
    // Increment unread count globally
    NotificationProvider().incrementCount();

    // ⚠️ Show notification for ANY message with a notification payload.
    // Do NOT require android != null — that silently drops valid messages.
    if (notification != null) {
      // Use a stable unique ID derived from message ID to avoid duplicates
      final int notifId = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      _localNotifications.show(
        notifId,
        notification.title ?? 'New Notification',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            // Fallback to app icon — smallIcon may be null for data-only messages
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        // Pass the entire data map as payload for tap-to-navigate
        payload: message.data.toString(),
      );

      // 🚀 AUTOMATICALLY OPEN BOTTOM SHEET FOR NEW BOOKINGS
      // This allows the merchant to see the request immediately without tapping the notification
      final type = message.data['notification_type'] ?? message.data['type'] ?? '';
      if (type == NotificationType.newBooking) {
        // Defer to async so we can retry waiting for context
        unawaited(NotificationService.showNewBookingSheet(message.data));
      }
    } else {
      // Data-only message (no notification block) — still log it
      debugPrint('⚠️ Data-only message received (no notification payload): ${message.data}');
    }
  }

  /// Handle navigation when a notification is tapped
  void _handleMessageOpen(RemoteMessage message) {
    debugPrint('📩 Notification Tapped: ${message.data}');
    
    // Backend sends 'notification_type', not 'type'
    final type = message.data['notification_type'] ?? message.data['type'] ?? '';
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

  static const int _maxDeviceRegistrationAttempts = 2;

  /// Register FCM token with backend. If the backend rejects the token as a global
  /// duplicate (e.g. still tied to another user's row), we rotate the FCM token
  /// and register once more — listing devices for the new user will not see it.
  ///
  /// Concurrency: [onTokenRefresh] and [registerTokenAfterLogin] can run back-to-back
  /// with the same string; the mutex and [_fcmSyncedWithBackend] avoid duplicate POSTs
  /// and the noisy "already exists" follow-up.
  Future<void> _registerTokenWithBackend(String initialToken) async {
    while (_registerInFlight != null) {
      await _registerInFlight!.future;
    }
    if (initialToken == _fcmSyncedWithBackend) {
      debugPrint('ℹ️ FCM token already synced with backend, skipping');
      return;
    }

    _registerInFlight = Completer<void>();
    try {
      var tokenToRegister = initialToken;
      for (var attempt = 0; attempt < _maxDeviceRegistrationAttempts; attempt++) {
        try {
          final isLoggedIn = await _authService.isLoggedIn();
          if (!isLoggedIn) {
            debugPrint('⚠️ User not logged in, skipping token registration');
            return;
          }
          final response = await _notificationService.registerDeviceToken(
            token: tokenToRegister,
            deviceType: defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
          );

          await _authService.setDeviceTokenId(response.id);
          _fcmToken = tokenToRegister;
          _fcmSyncedWithBackend = tokenToRegister;
          debugPrint('✅ FCM token registered with backend (ID: ${response.id})');
          return;
        } catch (e) {
          final message = e.toString().toLowerCase();
          final isDuplicate = message.contains('already exists') ||
              message.contains('unique') ||
              message.contains('duplicate');
          if (isDuplicate) {
            // Benign: another registration just completed with this exact token.
            if (tokenToRegister == _fcmSyncedWithBackend) {
              debugPrint('ℹ️ FCM token already on server (deduplicated)');
              return;
            }
            if (attempt < _maxDeviceRegistrationAttempts - 1) {
              debugPrint(
                '⚠️ FCM token rejected as duplicate; rotating and retrying...',
              );
              try {
                await _messaging.deleteToken();
                if (defaultTargetPlatform == TargetPlatform.iOS) {
                  await _messaging.getAPNSToken();
                }
                final newToken = await _messaging.getToken();
                if (newToken == null || newToken.isEmpty) {
                  debugPrint('❌ No FCM token after rotation');
                  return;
                }
                tokenToRegister = newToken;
                _fcmToken = newToken;
                continue;
              } catch (rotateError) {
                debugPrint('❌ FCM token rotation failed: $rotateError');
                return;
              }
            }
          }
          debugPrint('❌ Error registering FCM token with backend: $e');
          return;
        }
      }
    } finally {
      _registerInFlight?.complete();
      _registerInFlight = null;
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

  Future<void> _deleteFcmTokenSafely() async {
    try {
      await _messaging.deleteToken();
      debugPrint('✅ Firebase token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  /// Deactivate push device on the server and delete the FCM token in parallel
  /// so logout is not serialized on two network calls.
  Future<void> deactivateCurrentDevice() async {
    try {
      final tokenId = await _authService.getDeviceTokenId();
      final patch = (tokenId != null && tokenId.isNotEmpty)
          ? deactivateTokenOnLogout(tokenId)
          : Future<void>.value();
      final del = _deleteFcmTokenSafely();
      await Future.wait<void>([patch, del]);
      if (tokenId == null || tokenId.isEmpty) {
        debugPrint('⚠️ No device token ID found for deactivation');
      }
    } catch (e) {
      debugPrint('❌ Error in deactivateCurrentDevice: $e');
    } finally {
      _fcmSyncedWithBackend = null;
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
