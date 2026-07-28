import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/deals/domain/repositories/deals_repository.dart';

class CreateLoyaltyCheckinUseCase {
  CreateLoyaltyCheckinUseCase(this._repository);

  final DealsRepository _repository;

  Future<Result<Map<String, dynamic>>> call(String restaurantSlug) async {
    return _repository.createLoyaltyCheckIn(restaurantSlug: restaurantSlug);
  }
}
