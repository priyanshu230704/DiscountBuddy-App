import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class CreateMenuCategoryUseCase {
  CreateMenuCategoryUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call(Map<String, dynamic> data) =>
      _repository.createMenuCategory(data);
}
