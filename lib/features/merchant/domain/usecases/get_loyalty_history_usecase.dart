import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class GetLoyaltyHistoryUseCase {
  GetLoyaltyHistoryUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call({
    required int restaurantId,
    int? userId,
    String? status,
  }) =>
      _repository.getLoyaltyHistory(
        restaurantId: restaurantId,
        userId: userId,
        status: status,
      );
}
