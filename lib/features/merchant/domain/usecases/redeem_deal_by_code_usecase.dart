import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class RedeemDealByCodeUseCase {
  RedeemDealByCodeUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call(
    String redemptionCode, {
    required double price,
    required int peopleCount,
    int? restaurantId,
  }) =>
      _repository.redeemDealByCode(
        redemptionCode,
        price: price,
        peopleCount: peopleCount,
        restaurantId: restaurantId,
      );
}
