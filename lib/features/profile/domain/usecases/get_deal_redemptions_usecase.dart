import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/profile/domain/repositories/profile_repository.dart';
import 'package:discount_buddy/features/deals/models/deal_redemption.dart';

/// Get user's deal redemptions
class GetDealRedemptionsUseCase {
  GetDealRedemptionsUseCase(this._repository);
  final ProfileRepository _repository;

  Future<Result<List<DealRedemption>>> call() =>
      _repository.getDealRedemptions();
}
