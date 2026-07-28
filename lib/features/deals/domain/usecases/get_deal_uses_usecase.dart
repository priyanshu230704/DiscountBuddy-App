import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/deals/domain/repositories/deals_repository.dart';

class GetDealUsesUseCase {
  GetDealUsesUseCase(this._repository);

  final DealsRepository _repository;

  Future<Result<List<dynamic>>> call() async {
    return _repository.getDealUses();
  }
}
