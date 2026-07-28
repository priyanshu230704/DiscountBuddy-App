import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class ToggleDealStatusUseCase {
  ToggleDealStatusUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call(
    int dealId, {
    String? startDate,
    String? endDate,
  }) =>
      _repository.toggleDealStatus(dealId, startDate: startDate, endDate: endDate);
}
