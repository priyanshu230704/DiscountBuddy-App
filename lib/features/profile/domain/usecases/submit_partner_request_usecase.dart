import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/profile/domain/repositories/profile_repository.dart';

/// Submit a partner request
class SubmitPartnerRequestUseCase {
  SubmitPartnerRequestUseCase(this._repository);
  final ProfileRepository _repository;

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
