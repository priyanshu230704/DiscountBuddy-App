import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/loyalty/domain/repositories/loyalty_repository.dart';
import 'package:discount_buddy/features/loyalty/models/loyalty_card.dart';

/// Get all loyalty cards for the user.
class GetLoyaltyCardsUseCase {
  GetLoyaltyCardsUseCase(this._repository);

  final LoyaltyRepository _repository;

  Future<Result<List<LoyaltyCard>>> call() async {
    return await _repository.getLoyaltyCards();
  }
}
