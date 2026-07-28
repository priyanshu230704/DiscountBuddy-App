import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class GetMerchantRestaurantsUseCase {
  GetMerchantRestaurantsUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call({
    int? page,
    String? search,
    String? ordering,
    int? cityId,
  }) =>
      _repository.getMerchantRestaurants(
        page: page,
        search: search,
        ordering: ordering,
        cityId: cityId,
      );
}
