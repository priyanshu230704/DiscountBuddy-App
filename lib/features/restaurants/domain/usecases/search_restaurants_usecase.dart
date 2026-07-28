import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant.dart';

/// Search for restaurants by query
class SearchRestaurantsUseCase {
  SearchRestaurantsUseCase(this._repository);
  final RestaurantRepository _repository;

  Future<Result<List<Restaurant>>> call({
    required String query,
    double? latitude,
    double? longitude,
  }) =>
      _repository.searchRestaurants(
        query: query,
        latitude: latitude,
        longitude: longitude,
      );
}
