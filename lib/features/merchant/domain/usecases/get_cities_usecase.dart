import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class GetCitiesUseCase {
  GetCitiesUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call({
    int? countryId,
    bool? isActive,
    String? search,
    String? ordering,
  }) =>
      _repository.getCities(
        countryId: countryId,
        isActive: isActive,
        search: search,
        ordering: ordering,
      );
}
