import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class GetMerchantDealsUseCase {
  GetMerchantDealsUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call({
    int? page,
    int? restaurantId,
    String? dealType,
    bool? isFeatured,
    String? search,
    String? ordering,
  }) =>
      _repository.getMerchantDeals(
        page: page,
        restaurantId: restaurantId,
        dealType: dealType,
        isFeatured: isFeatured,
        search: search,
        ordering: ordering,
      );
}
