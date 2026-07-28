import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant.dart';

/// Get user's saved/favorited restaurants
class GetSavedRestaurantsUseCase {
  GetSavedRestaurantsUseCase(this._repository);
  final RestaurantRepository _repository;

  Future<Result<List<Restaurant>>> call({
    double? latitude,
    double? longitude,
  }) =>
      _repository.getSavedRestaurants(
        latitude: latitude,
        longitude: longitude,
      );
}
