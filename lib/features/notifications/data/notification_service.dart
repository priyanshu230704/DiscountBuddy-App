import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:discount_buddy/features/notifications/models/notification.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'package:discount_buddy/core/network/api_service.dart';
import 'package:discount_buddy/core/config/api_endpoints.dart';
import 'package:discount_buddy/widgets/generic_bottom_sheet.dart';
import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/core/theme/app_typography.dart';
import 'package:discount_buddy/core/utils/date_time_utils.dart';
import 'package:discount_buddy/core/utils/navigator_key.dart';
import 'package:discount_buddy/core/device/device_id_service.dart';

/// API / FCM [booking_date] is UTC ISO-8601; show in the user's local zone.
String _formatNotificationBookingDate(Object? value) {
  if (value == null) return 'N/A';
  final s = value.toString().trim();
  if (s.isEmpty || s == 'N/A') return 'N/A';
  final parsed = DateTimeUtils.tryParseBookingInstant(s);
  if (parsed == null) return s;
  return DateTimeUtils.formatDateTime24h(parsed);
}

/// Service for managing notifications and device tokens
class NotificationService {
  final ApiService _apiService = ApiService();

  // ==================== Device Token Management ====================

  /// Register or update FCM device token
  Future<DeviceToken> registerDeviceToken({
    required String token,
    required String deviceType, // 'android', 'ios', or 'web'
  }) async {
    final deviceId = await DeviceIdService.getOrCreate();
    final response = await _apiService.post(
      ApiEndpoints.registerDeviceToken,
      body: {
        'token': token,
        'device_type': deviceType,
        'device_id': deviceId,
      },
      type: ApiType.user,
    );

    return DeviceToken.fromJson(response);
  }

  /// Get all device tokens for the authenticated user
  Future<List<DeviceToken>> getDeviceTokens() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.deviceTokens,
        type: ApiType.user,
      );

      // Handle both array response and wrapped response
      List<dynamic> tokensJson = [];
      
      if (response['results'] is List<dynamic>) {
        // Paginated response with 'results' key
        tokensJson = response['results'] as List<dynamic>;
      } else if (response['data'] is List<dynamic>) {
        // Wrapped in 'data' key
        tokensJson = response['data'] as List<dynamic>;
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
  Future<int> getUnreadCount({required bool isMerchant}) async {
    try {
      final response = await _apiService.get(
        isMerchant
            ? ApiEndpoints.merchantUnreadNotificationCount
            : ApiEndpoints.userUnreadNotificationCount,
        type: isMerchant ? ApiType.merchant : ApiType.user,
      );

      return response['count'] as int;
    } catch (e) {
      debugPrint('❌ Failed to get unread count: $e');
      return 0;
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

  /// Show the NEW_BOOKING bottom sheet; if context is not ready, retry up to 3s.
  /// Called from [FirebaseMessagingService] when a NEW_BOOKING arrives in foreground.
  static Future<void> showNewBookingSheet(
    Map<String, dynamic>? data,
  ) async {
    const maxRetries = 30;
    const retryInterval = Duration(milliseconds: 100);

    for (var i = 0; i < maxRetries; i++) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        _buildAndShowNewBookingSheet(context, data);
        return;
      }
      await Future.delayed(retryInterval);
    }
    debugPrint('❌ Failed to show new booking sheet; context unavailable after 3s');
  }

  /// Build and show the NEW_BOOKING bottom sheet.
  static void _buildAndShowNewBookingSheet(
    BuildContext context,
    Map<String, dynamic>? data,
  ) {
    final customerName = data?['customer_name'] ?? 'A customer';
    final guests = data?['number_of_guests'] ?? 'N/A';
    final bookingDate = _formatNotificationBookingDate(
      data?['booking_date'] ?? data?['booking_datetime'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GenericBottomSheet(
        title: 'New Booking Request',
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Details',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            bookingDate,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(Icons.person_outline, 'Customer', customerName),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.group_outlined, 'Guests', '$guests Person(s)'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close bottom sheet
                    Get.toNamed(AppRoutes.merchantBookings);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'View All Bookings',
                    style: AppTypography.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigates to the appropriate screen based on notification type
  static void handleNotificationNavigation(
    BuildContext context,
    String type,
    Map<String, dynamic>? data,
  ) {
    switch (type) {
      // Merchant specific notifications
      case NotificationType.newBooking:
        if (context.mounted) {
          _buildAndShowNewBookingSheet(context, data);
        } else {
          showNewBookingSheet(data);
        }
        break;

      case NotificationType.newReview:
        Get.toNamed(AppRoutes.merchantReviews);
        break;

      case NotificationType.milestoneEarnings:
        Get.toNamed(AppRoutes.merchantAnalytics);
        break;

      case NotificationType.merchantDealRedeemed:
        Get.toNamed(AppRoutes.merchantRedemptionHistory);
        break;

      case NotificationType.merchantReminder:
        Get.toNamed(AppRoutes.merchantBookings);
        break;

      // Customer specific notifications
      case NotificationType.favDeal:
        final id = data?['restaurant_id'] ?? '';
        if (id.toString().isNotEmpty) {
          Get.toNamed(
            AppRoutes.restaurantDetails,
            arguments: {'slug': id.toString()},
          );
        }
        break;

      case NotificationType.dealRedeemed:
      case NotificationType.bookingConfirmed:
        // Redirect to activity/bookings tab (index 2 in MainNavigation)
        Get.offAllNamed(
          AppRoutes.home,
          arguments: {'initialIndex': 2},
        );
        break;

      default:
        // Default to home or just stay on page
        debugPrint('⚠️ Unknown notification type for navigation: $type');
        Get.offAllNamed(AppRoutes.home);
    }
  }

  static Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
