import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class GetMerchantBookingsUseCase {
  GetMerchantBookingsUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call({
    int? restaurantId,
    String? status,
    String? startDate,
    String? endDate,
  }) =>
      _repository.getMerchantBookings(
        restaurantId: restaurantId,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
}
