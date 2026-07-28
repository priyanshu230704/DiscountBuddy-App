import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class RedeemDealByQRUseCase {
  RedeemDealByQRUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call(
    String qrData, {
    required double price,
    required int peopleCount,
    int? restaurantId,
  }) =>
      _repository.redeemDealByQR(
        qrData,
        price: price,
        peopleCount: peopleCount,
        restaurantId: restaurantId,
      );
}
