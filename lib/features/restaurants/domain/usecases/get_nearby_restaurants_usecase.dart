import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant.dart';

/// Get nearby restaurants within a radius
class GetNearbyRestaurantsUseCase {
  GetNearbyRestaurantsUseCase(this._repository);
  final RestaurantRepository _repository;

  Future<Result<List<Restaurant>>> call({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) =>
      _repository.getNearbyRestaurants(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
}
