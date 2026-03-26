import 'package:flutter/material.dart';
import '../models/notification.dart';
import 'api_service.dart';
import '../config/api_endpoints.dart';
import '../pages/merchant/merchant_bookings_page.dart';
import '../pages/merchant/merchant_reviews_page.dart';
import '../pages/merchant/merchant_redemption_history_page.dart';
import '../pages/merchant/merchant_analytics_page.dart';
import '../pages/restaurant_details_page.dart';
import '../pages/main_navigation.dart';

/// Service for managing notifications and device tokens
class NotificationService {
  final ApiService _apiService = ApiService();

  // ==================== Device Token Management ====================

  /// Register or update FCM device token
  Future<DeviceToken> registerDeviceToken({
    required String token,
    required String deviceType, // 'android', 'ios', or 'web'
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.registerDeviceToken,
        body: {'token': token, 'device_type': deviceType},
        type: ApiType.user,
      );

      return DeviceToken.fromJson(response);
    } catch (e) {
      throw Exception('Failed to register device token: $e');
    }
  }

  /// Get all device tokens for the authenticated user
  Future<List<DeviceToken>> getDeviceTokens() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.deviceTokens,
        type: ApiType.user,
      );

      // Handle both array response and wrapped response
      List<dynamic> tokensJson;
      if (response['data'] != null) {
        tokensJson = response['data'] as List<dynamic>;
      } else {
        // If response is already a list wrapped in 'data' key, or direct list
        tokensJson = [];
      }

      return tokensJson
          .map((json) => DeviceToken.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get device tokens: $e');
    }
  }

  /// Deactivate a device token (e.g., on logout)
  Future<void> deactivateDeviceToken(String tokenId) async {
    try {
      await _apiService.patch(
        ApiEndpoints.deactivateDeviceToken(tokenId),
        type: ApiType.user,
      );
    } catch (e) {
      throw Exception('Failed to deactivate device token: $e');
    }
  }

  /// Delete a device token permanently
  Future<void> deleteDeviceToken(String tokenId) async {
    try {
      await _apiService.delete(
        ApiEndpoints.deleteDeviceToken(tokenId),
        type: ApiType.user,
      );
    } catch (e) {
      throw Exception('Failed to delete device token: $e');
    }
  }

  // ==================== Notification Management ====================

  /// Get paginated list of notifications
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.notifications,
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
        type: ApiType.user,
      );

      return NotificationListResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  /// Get a single notification by ID
  Future<NotificationModel> getNotification(String notificationId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.notificationDetail(notificationId),
        type: ApiType.user,
      );

      return NotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get notification: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.unreadNotificationCount,
        type: ApiType.user,
      );

      return response['count'] as int;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.patch(
        ApiEndpoints.markNotificationRead(notificationId),
        type: ApiType.user,
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final response = await _apiService.patch(
        ApiEndpoints.markAllNotificationsRead,
        type: ApiType.user,
      );

      return response['count'] as int;
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  // ==================== Helper Methods ====================

  /// Get notification icon based on type
  String getNotificationIcon(String notificationType) {
    switch (notificationType) {
      case NotificationType.bookingConfirmed:
        return '🎉';
      case NotificationType.favDeal:
        return '🔥';
      case NotificationType.dealRedeemed:
        return '✅';
      case NotificationType.system:
        return '📢';
      case NotificationType.newBooking:
        return '📅';
      case NotificationType.newReview:
        return '✍️';
      case NotificationType.milestoneEarnings:
        return '🏆';
      case NotificationType.merchantDealRedeemed:
        return '🎉';
      default:
        return '🔔';
    }
  }

  /// Get notification color based on type
  String getNotificationColor(String notificationType) {
    switch (notificationType) {
      case NotificationType.bookingConfirmed:
        return '#10B981'; // Green
      case NotificationType.favDeal:
        return '#FF7A00'; // Orange
      case NotificationType.dealRedeemed:
        return '#7C3AED'; // Purple
      case NotificationType.system:
        return '#3B82F6'; // Blue
      case NotificationType.newBooking:
        return '#F59E0B'; // Amber/Gold
      case NotificationType.newReview:
        return '#EC4899'; // Pink
      case NotificationType.milestoneEarnings:
        return '#FACC15'; // Yellow/Milestone
      case NotificationType.merchantDealRedeemed:
        return '#8B5CF6'; // Purple
      default:
        return '#6B7280'; // Gray
    }
  }
  // ==================== Navigation Handling ====================

  /// Navigates to the appropriate screen based on notification type
  static void handleNotificationNavigation(
    BuildContext context,
    String type,
    Map<String, dynamic>? data,
  ) {
    switch (type) {
      // Merchant specific notifications
      case NotificationType.newBooking:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MerchantBookingsPage(),
          ),
        );
        break;

      case NotificationType.newReview:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MerchantReviewsPage(),
          ),
        );
        break;

      case NotificationType.milestoneEarnings:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MerchantAnalyticsPage(),
          ),
        );
        break;

      case NotificationType.merchantDealRedeemed:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MerchantRedemptionHistoryPage(),
          ),
        );
        break;

      // Customer specific notifications
      case NotificationType.favDeal:
        final id = data?['restaurant_id'] ?? '';
        if (id.toString().isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailsPage(slug: id.toString()),
            ),
          );
        }
        break;

      case NotificationType.dealRedeemed:
      case NotificationType.bookingConfirmed:
        // Redirect to activity/bookings tab (index 2 in MainNavigation)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigation(initialIndex: 2),
          ),
          (route) => false,
        );
        break;

      default:
        // Default to home or just stay on page
        debugPrint('⚠️ Unknown notification type for navigation: $type');
        Navigator.pushReplacementNamed(context, '/home');
    }
  }
}
