import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/notifications/domain/repositories/notifications_repository.dart';

class GetUnreadCountUseCase {
  GetUnreadCountUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Result<int>> call({required bool isMerchant}) async {
    return _repository.getUnreadCount(isMerchant: isMerchant);
  }
}
