import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class ClaimLoyaltyRewardUseCase {
  ClaimLoyaltyRewardUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call({
    required int restaurantId,
    required int userId,
  }) =>
      _repository.claimLoyaltyReward(restaurantId: restaurantId, userId: userId);
}
