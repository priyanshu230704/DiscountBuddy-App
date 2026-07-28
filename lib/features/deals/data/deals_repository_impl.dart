import 'package:discount_buddy/core/domain/error_mapper.dart';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/deals/data/deals_service.dart';
import 'package:discount_buddy/features/deals/domain/repositories/deals_repository.dart';
import 'package:discount_buddy/features/deals/models/voucher.dart';

class DealsRepositoryImpl implements DealsRepository {
  DealsRepositoryImpl({DealsService? service})
      : _service = service ?? DealsService();

  final DealsService _service;

  @override
  Future<Result<PaginatedVouchers>> getUserVouchers({
    required int page,
    required int pageSize,
  }) async {
    try {
      final result = await _service.getUserVouchers(
        page: page,
        pageSize: pageSize,
      );
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not load vouchers'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> claimDeal({
    required int dealId,
  }) async {
    try {
      final result = await _service.claimDeal(dealId);
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not claim deal'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createLoyaltyCheckIn({
    required String restaurantSlug,
  }) async {
    try {
      final result = await _service.createLoyaltyOnlyVisit(restaurantSlug);
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not create loyalty check-in'));
    }
  }

  @override
  Future<Result<List<dynamic>>> getDealUses() async {
    try {
      final result = await _service.getDealUses();
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not load deal uses'));
    }
  }
}
