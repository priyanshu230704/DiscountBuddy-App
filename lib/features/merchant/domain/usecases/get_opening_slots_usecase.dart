import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class GetOpeningSlotsUseCase {
  GetOpeningSlotsUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call({int? restaurantId}) =>
      _repository.getOpeningSlots(restaurantId: restaurantId);
}
