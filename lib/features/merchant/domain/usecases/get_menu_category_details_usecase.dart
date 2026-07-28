import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class GetMenuCategoryDetailsUseCase {
  GetMenuCategoryDetailsUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call(int id, {int? restaurantId}) =>
      _repository.getMenuCategoryDetails(id, restaurantId: restaurantId);
}
