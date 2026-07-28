import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';
import 'package:discount_buddy/features/deals/models/deal_redemption.dart';

/// Intent-based profile repository
abstract class ProfileRepository {
  /// Get user profile stats (saved restaurants, levels, deals, etc.)
  Future<Result<ProfileStats>> getProfileStats();

  /// Get user's deal redemptions/savings history
  Future<Result<List<DealRedemption>>> getDealRedemptions();

  /// Submit a partner request for a new restaurant
  Future<Result<void>> submitPartnerRequest({
    required String restaurantName,
    required String contactName,
    required String email,
    required String phone,
    required String cityName,
    String? website,
    String? comments,
  });
}
