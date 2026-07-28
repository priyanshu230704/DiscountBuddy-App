import 'package:discount_buddy/core/domain/error_mapper.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/data/restaurant_service.dart';
import 'package:discount_buddy/features/profile/domain/repositories/profile_repository.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';
import 'package:discount_buddy/features/deals/models/deal_redemption.dart';

/// Implementation of ProfileRepository
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({RestaurantService? service})
      : _service = service ?? RestaurantService();

  final RestaurantService _service;

  Failure _mapError(Object e, {String fallback = 'Something went wrong'}) =>
      mapToFailure(e, fallback: fallback);

  @override
  Future<Result<ProfileStats>> getProfileStats() async {
    try {
      final stats = await _service.getProfileStats();
      return Success(stats);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load profile stats'));
    }
  }

  @override
  Future<Result<List<DealRedemption>>> getDealRedemptions() async {
    try {
      final redemptions = await _service.getUserDealRedemptions();
      return Success(redemptions);
    } catch (e) {
      return Err(
        _mapError(e, fallback: 'Failed to load deal redemptions'),
      );
    }
  }

  @override
  Future<Result<void>> submitPartnerRequest({
    required String restaurantName,
    required String contactName,
    required String email,
    required String phone,
    required String cityName,
    String? website,
    String? comments,
  }) async {
    try {
      await _service.submitPartnerRequest(
        restaurantName: restaurantName,
        contactName: contactName,
        email: email,
        phone: phone,
        cityName: cityName,
        website: website,
        comments: comments,
      );
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to submit partner request'));
    }
  }
}
