import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';

/// Submit a partner request to become a restaurant partner
class SubmitPartnerRequestUseCase {
  SubmitPartnerRequestUseCase(this._repository);
  final RestaurantRepository _repository;

  Future<Result<void>> call({
    required String restaurantName,
    required String contactName,
    required String email,
    required String phone,
    required String cityName,
    String? website,
    String? comments,
  }) =>
      _repository.submitPartnerRequest(
        restaurantName: restaurantName,
        contactName: contactName,
        email: email,
        phone: phone,
        cityName: cityName,
        website: website,
        comments: comments,
      );
}
