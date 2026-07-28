import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class ClaimLoyaltyRewardByQRUseCase {
  ClaimLoyaltyRewardByQRUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call(String qrData) =>
      _repository.claimLoyaltyRewardByQR(qrData);
}
