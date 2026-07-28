import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';

/// Get user profile stats (saved restaurants, levels, etc.)
class GetProfileStatsUseCase {
  GetProfileStatsUseCase(this._repository);
  final RestaurantRepository _repository;

  Future<Result<ProfileStats>> call() => _repository.getProfileStats();
}
