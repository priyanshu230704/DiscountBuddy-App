import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant.dart';

/// Get all restaurants with optional filters
class GetRestaurantsUseCase {
  GetRestaurantsUseCase(this._repository);
  final RestaurantRepository _repository;

  Future<Result<List<Restaurant>>> call({
    int? cityId,
    int? page,
    double? latitude,
    double? longitude,
    String? search,
    int? cuisines,
    int? day,
    String? time,
  }) =>
      _repository.getRestaurants(
        cityId: cityId,
        page: page,
        latitude: latitude,
        longitude: longitude,
        search: search,
        cuisines: cuisines,
        day: day,
        time: time,
      );
}
