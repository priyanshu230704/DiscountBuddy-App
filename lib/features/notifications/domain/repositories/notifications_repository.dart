import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/notifications/models/notification.dart';

/// Intent-based notifications contract.
abstract class NotificationsRepository {
  Future<Result<NotificationListResponse>> getNotifications({
    required int page,
    required int pageSize,
  });

  Future<Result<NotificationModel>> getNotification(String notificationId);

  Future<Result<int>> getUnreadCount({required bool isMerchant});

  Future<Result<void>> markAsRead(String notificationId);

  Future<Result<int>> markAllAsRead();
}
