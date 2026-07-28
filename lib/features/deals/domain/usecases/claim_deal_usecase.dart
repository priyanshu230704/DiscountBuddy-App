import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/deals/domain/repositories/deals_repository.dart';

class ClaimDealUseCase {
  ClaimDealUseCase(this._repository);

  final DealsRepository _repository;

  Future<Result<Map<String, dynamic>>> claimDeal(int dealId) async {
    return _repository.claimDeal(dealId: dealId);
  }
}
