import 'package:discount_buddy/core/domain/error_mapper.dart';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/notifications/data/notification_service.dart';
import 'package:discount_buddy/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:discount_buddy/features/notifications/models/notification.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({NotificationService? service})
      : _service = service ?? NotificationService();

  final NotificationService _service;

  @override
  Future<Result<NotificationListResponse>> getNotifications({
    required int page,
    required int pageSize,
  }) async {
    try {
      final result = await _service.getNotifications(
        page: page,
        pageSize: pageSize,
      );
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not load notifications'));
    }
  }

  @override
  Future<Result<NotificationModel>> getNotification(String notificationId) async {
    try {
      final result = await _service.getNotification(notificationId);
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not load notification'));
    }
  }

  @override
  Future<Result<int>> getUnreadCount({required bool isMerchant}) async {
    try {
      final result = await _service.getUnreadCount(isMerchant: isMerchant);
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not get unread count'));
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      return const Success(null);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not mark as read'));
    }
  }

  @override
  Future<Result<int>> markAllAsRead() async {
    try {
      final result = await _service.markAllAsRead();
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not mark all as read'));
    }
  }
}
