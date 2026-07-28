import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class GetFacilitiesUseCase {
  GetFacilitiesUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call({
    String? search,
    String? ordering,
  }) =>
      _repository.getFacilities(search: search, ordering: ordering);
}
