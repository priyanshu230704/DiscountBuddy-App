import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class ClaimLoyaltyRewardByCodeUseCase {
  ClaimLoyaltyRewardByCodeUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call(String rewardCode) =>
      _repository.claimLoyaltyRewardByCode(rewardCode);
}
