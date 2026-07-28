import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant.dart';

/// Get restaurant basic info by slug
class GetRestaurantBySlugUseCase {
  GetRestaurantBySlugUseCase(this._repository);
  final RestaurantRepository _repository;

  Future<Result<Restaurant>> call(
    String slug, {
    double? latitude,
    double? longitude,
  }) =>
      _repository.getRestaurantBySlug(
        slug,
        latitude: latitude,
        longitude: longitude,
      );
}
