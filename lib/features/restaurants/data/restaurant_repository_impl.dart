import 'package:discount_buddy/core/domain/error_mapper.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/restaurants/data/restaurant_service.dart';
import 'package:discount_buddy/features/restaurants/domain/repositories/restaurant_repository.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant_detail.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';

/// Implementation of RestaurantRepository that wraps RestaurantService
class RestaurantRepositoryImpl implements RestaurantRepository {
  RestaurantRepositoryImpl({RestaurantService? service})
      : _service = service ?? RestaurantService();

  final RestaurantService _service;

  Failure _mapError(Object e, {String fallback = 'Something went wrong'}) =>
      mapToFailure(e, fallback: fallback);

  @override
  Future<Result<List<Restaurant>>> searchRestaurants({
    required String query,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final restaurants = await _service.searchRestaurants(
        query: query,
        latitude: latitude,
        longitude: longitude,
      );
      return Success(restaurants);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to search restaurants'));
    }
  }

  @override
  Future<Result<List<Restaurant>>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) async {
    try {
      final restaurants = await _service.getNearbyRestaurants(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      return Success(restaurants);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load nearby restaurants'));
    }
  }

  @override
  Future<Result<List<Restaurant>>> getRestaurants({
    int? cityId,
    int? page,
    double? latitude,
    double? longitude,
    String? search,
    int? cuisines,
    int? day,
    String? time,
  }) async {
    try {
      final restaurants = await _service.getRestaurants(
        cityId: cityId,
        page: page,
        latitude: latitude,
        longitude: longitude,
        search: search,
        cuisines: cuisines,
        day: day,
        time: time,
      );
      return Success(restaurants);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load restaurants'));
    }
  }

  @override
  Future<Result<List<Restaurant>>> getSavedRestaurants({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final restaurants = await _service.getSavedRestaurants(
        latitude: latitude,
        longitude: longitude,
      );
      return Success(restaurants);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load saved restaurants'));
    }
  }

  @override
  Future<Result<RestaurantDetail>> getRestaurantDetailBySlug(
    String slug, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final detail = await _service.getRestaurantDetailBySlug(
        slug,
        latitude: latitude,
        longitude: longitude,
      );
      return Success(detail);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load restaurant details'));
    }
  }

  @override
  Future<Result<Restaurant>> getRestaurantBySlug(
    String slug, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final restaurant = await _service.getRestaurantBySlug(
        slug,
        latitude: latitude,
        longitude: longitude,
      );
      return Success(restaurant);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load restaurant'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getCuisines() async {
    try {
      final cuisines = await _service.getCuisines();
      return Success(cuisines);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load cuisines'));
    }
  }

  @override
  Future<Result<bool>> toggleFavourite(String slug, bool isFavourite) async {
    try {
      final newStatus = await _service.toggleFavourite(slug, isFavourite);
      return Success(newStatus);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to toggle favorite'));
    }
  }

  @override
  Future<Result<void>> addReview({
    required int restaurantId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _service.addReview(
        restaurantId: restaurantId,
        rating: rating,
        comment: comment,
      );
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to add review'));
    }
  }

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
