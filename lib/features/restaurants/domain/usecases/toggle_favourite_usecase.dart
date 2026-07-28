import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';

/// Toggle a restaurant's favorite status
class ToggleFavouriteUseCase {
  ToggleFavouriteUseCase(this._repository);
  final RestaurantRepository _repository;

  Future<Result<bool>> call(String slug, bool isFavourite) =>
      _repository.toggleFavourite(slug, isFavourite);
}
