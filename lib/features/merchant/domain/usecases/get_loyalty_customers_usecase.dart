import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class GetLoyaltyCustomersUseCase {
  GetLoyaltyCustomersUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call({
    required int restaurantId,
    bool? eligibleOnly,
  }) =>
      _repository.getLoyaltyCustomers(
        restaurantId: restaurantId,
        eligibleOnly: eligibleOnly,
      );
}
