import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class DeleteDealUseCase {
  DeleteDealUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<void>> call(int dealId) => _repository.deleteDeal(dealId);
}
