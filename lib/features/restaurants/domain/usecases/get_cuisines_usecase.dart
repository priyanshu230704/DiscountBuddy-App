import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';

/// Get all available cuisines
class GetCuisinesUseCase {
  GetCuisinesUseCase(this._repository);
  final RestaurantRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call() =>
      _repository.getCuisines();
}
