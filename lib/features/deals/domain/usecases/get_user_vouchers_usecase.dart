import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/deals/domain/repositories/deals_repository.dart';
import 'package:discount_buddy/features/deals/models/voucher.dart';

class GetUserVouchersUseCase {
  GetUserVouchersUseCase(this._repository);

  final DealsRepository _repository;

  Future<Result<PaginatedVouchers>> call({
    required int page,
    required int pageSize,
  }) async {
    return _repository.getUserVouchers(page: page, pageSize: pageSize);
  }
}
