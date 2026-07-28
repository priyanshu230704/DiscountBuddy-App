import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class CreateDealUseCase {
  CreateDealUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call(Map<String, dynamic> data) =>
      _repository.createDeal(data);
}
