import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/notifications/domain/repositories/notifications_repository.dart';

class MarkAllNotificationsReadUseCase {
  MarkAllNotificationsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Result<int>> call() async {
    return _repository.markAllAsRead();
  }
}
