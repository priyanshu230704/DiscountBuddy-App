import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class GetMerchantAnalyticsUseCase {
  GetMerchantAnalyticsUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call({
    int? restaurantId,
    int period = 30,
  }) =>
      _repository.getMerchantAnalytics(restaurantId: restaurantId, period: period);
}
