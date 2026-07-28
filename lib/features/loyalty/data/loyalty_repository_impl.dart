import 'package:discount_buddy/core/domain/error_mapper.dart';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/loyalty/domain/repositories/loyalty_repository.dart';
import 'package:discount_buddy/features/loyalty/models/loyalty_card.dart';
import 'package:discount_buddy/features/restaurants/data/restaurant_service.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  LoyaltyRepositoryImpl({RestaurantService? service})
    : _service = service ?? RestaurantService();

  final RestaurantService _service;

  @override
  Future<Result<List<LoyaltyCard>>> getLoyaltyCards() async {
    try {
      final cards = await _service.getLoyaltyCards();
      return Success(cards);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Failed to load loyalty cards'));
    }
  }
}
