import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant_detail.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';

/// Intent-based restaurant repository — not a mirror of RestaurantService.
/// Groups methods by user intent (search, browse, details, manage favorites, review).
abstract class RestaurantRepository {
  /// Search restaurants by query, optionally filtered by location
  Future<Result<List<Restaurant>>> searchRestaurants({
    required String query,
    double? latitude,
    double? longitude,
  });

  /// Get nearby restaurants within radius at given coordinates
  Future<Result<List<Restaurant>>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radius,
  });

  /// Get all restaurants, optionally filtered by city, cuisine, time
  Future<Result<List<Restaurant>>> getRestaurants({
    int? cityId,
    int? page,
    double? latitude,
    double? longitude,
    String? search,
    int? cuisines,
    int? day,
    String? time,
  });

  /// Get user's saved/favorited restaurants
  Future<Result<List<Restaurant>>> getSavedRestaurants({
    double? latitude,
    double? longitude,
  });

  /// Get full details for a restaurant by slug (includes reviews, menu)
  Future<Result<RestaurantDetail>> getRestaurantDetailBySlug(
    String slug, {
    double? latitude,
    double? longitude,
  });

  /// Get restaurant basic info by slug
  Future<Result<Restaurant>> getRestaurantBySlug(
    String slug, {
    double? latitude,
    double? longitude,
  });

  /// Get all available cuisines
  Future<Result<List<Map<String, dynamic>>>> getCuisines();

  /// Toggle restaurant favorite status
  Future<Result<bool>> toggleFavourite(String slug, bool isFavourite);

  /// Add a review for a restaurant
  Future<Result<void>> addReview({
    required int restaurantId,
    required int rating,
    required String comment,
  });

  /// Get profile stats (saved restaurants count, deals used, etc.)
  Future<Result<ProfileStats>> getProfileStats();

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
