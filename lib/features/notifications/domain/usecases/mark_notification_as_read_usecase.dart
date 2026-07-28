import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/notifications/domain/repositories/notifications_repository.dart';

class MarkNotificationAsReadUseCase {
  MarkNotificationAsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Result<void>> call(String notificationId) async {
    return _repository.markAsRead(notificationId);
  }
}
