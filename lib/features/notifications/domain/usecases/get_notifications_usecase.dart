import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:discount_buddy/features/notifications/models/notification.dart';

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Result<NotificationListResponse>> call({
    required int page,
    required int pageSize,
  }) async {
    return _repository.getNotifications(page: page, pageSize: pageSize);
  }
}
