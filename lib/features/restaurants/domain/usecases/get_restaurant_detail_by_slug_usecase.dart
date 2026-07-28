import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant_detail.dart';

/// Get full restaurant details by slug
class GetRestaurantDetailBySlugUseCase {
  GetRestaurantDetailBySlugUseCase(this._repository);
  final RestaurantRepository _repository;

  Future<Result<RestaurantDetail>> call(
    String slug, {
    double? latitude,
    double? longitude,
  }) =>
      _repository.getRestaurantDetailBySlug(
        slug,
        latitude: latitude,
        longitude: longitude,
      );
}
