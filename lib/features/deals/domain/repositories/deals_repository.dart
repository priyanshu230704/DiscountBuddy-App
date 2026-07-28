import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/deals/models/voucher.dart';

/// Intent-based deals contract.
abstract class DealsRepository {
  Future<Result<PaginatedVouchers>> getUserVouchers({
    required int page,
    required int pageSize,
  });

  Future<Result<Map<String, dynamic>>> claimDeal({
    required int dealId,
  });

  Future<Result<Map<String, dynamic>>> createLoyaltyCheckIn({
    required String restaurantSlug,
  });

  Future<Result<List<dynamic>>> getDealUses();
}
