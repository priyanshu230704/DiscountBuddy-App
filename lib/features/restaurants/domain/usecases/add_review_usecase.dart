import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';

/// Add a review for a restaurant
class AddReviewUseCase {
  AddReviewUseCase(this._repository);
  final RestaurantRepository _repository;

  Future<Result<void>> call({
    required int restaurantId,
    required int rating,
    required String comment,
  }) =>
      _repository.addReview(
        restaurantId: restaurantId,
        rating: rating,
        comment: comment,
      );
}
