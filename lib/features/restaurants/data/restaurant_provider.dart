import 'package:flutter/foundation.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:discount_buddy/features/restaurants/domain/usecases/add_review_usecase.dart';
import 'package:discount_buddy/features/restaurants/domain/usecases/get_cuisines_usecase.dart';
import 'package:discount_buddy/features/restaurants/domain/usecases/get_nearby_restaurants_usecase.dart';
import 'package:discount_buddy/features/restaurants/domain/usecases/get_profile_stats_usecase.dart';
import 'package:discount_buddy/features/restaurants/domain/usecases/get_restaurant_by_slug_usecase.dart';
import 'package:discount_buddy/features/restaurants/domain/usecases/get_restaurant_detail_by_slug_usecase.dart';
import 'package:discount_buddy/features/restaurants/domain/usecases/get_restaurants_usecase.dart';
import 'package:discount_buddy/features/restaurants/domain/usecases/get_saved_restaurants_usecase.dart';
import 'package:discount_buddy/features/restaurants/domain/usecases/search_restaurants_usecase.dart';
import 'package:discount_buddy/features/restaurants/domain/usecases/submit_partner_request_usecase.dart';
import 'package:discount_buddy/features/restaurants/domain/usecases/toggle_favourite_usecase.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant.dart';
import 'package:discount_buddy/features/restaurants/models/restaurant_detail.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';

/// Presentation state for restaurants. Holds state, calls one use case, maps Result.
class RestaurantProvider extends ChangeNotifier {
  RestaurantProvider() {
    final repo = RestaurantRepositoryImpl();

    _searchRestaurantsUseCase = SearchRestaurantsUseCase(repo);
    _getNearbyRestaurantsUseCase = GetNearbyRestaurantsUseCase(repo);
    _getRestaurantsUseCase = GetRestaurantsUseCase(repo);
    _getSavedRestaurantsUseCase = GetSavedRestaurantsUseCase(repo);
    _getRestaurantDetailBySlugUseCase = GetRestaurantDetailBySlugUseCase(repo);
    _getRestaurantBySlugUseCase = GetRestaurantBySlugUseCase(repo);
    _getCuisinesUseCase = GetCuisinesUseCase(repo);
    _toggleFavouriteUseCase = ToggleFavouriteUseCase(repo);
    _addReviewUseCase = AddReviewUseCase(repo);
    _getProfileStatsUseCase = GetProfileStatsUseCase(repo);
    _submitPartnerRequestUseCase = SubmitPartnerRequestUseCase(repo);
  }

  late SearchRestaurantsUseCase _searchRestaurantsUseCase;
  late GetNearbyRestaurantsUseCase _getNearbyRestaurantsUseCase;
  late GetRestaurantsUseCase _getRestaurantsUseCase;
  late GetSavedRestaurantsUseCase _getSavedRestaurantsUseCase;
  late GetRestaurantDetailBySlugUseCase _getRestaurantDetailBySlugUseCase;
  late GetRestaurantBySlugUseCase _getRestaurantBySlugUseCase;
  late GetCuisinesUseCase _getCuisinesUseCase;
  late ToggleFavouriteUseCase _toggleFavouriteUseCase;
  late AddReviewUseCase _addReviewUseCase;
  late GetProfileStatsUseCase _getProfileStatsUseCase;
  late SubmitPartnerRequestUseCase _submitPartnerRequestUseCase;

  List<Restaurant> _restaurants = [];
  List<Restaurant> _nearbyRestaurants = [];
  List<Restaurant> _savedRestaurants = [];
  RestaurantDetail? _restaurantDetail;
  Restaurant? _restaurant;
  List<Map<String, dynamic>> _cuisines = [];
  ProfileStats? _profileStats;

  Failure? _error;
  bool _isLoading = false;

  // Getters
  List<Restaurant> get restaurants => _restaurants;
  List<Restaurant> get nearbyRestaurants => _nearbyRestaurants;
  List<Restaurant> get savedRestaurants => _savedRestaurants;
  RestaurantDetail? get restaurantDetail => _restaurantDetail;
  Restaurant? get restaurant => _restaurant;
  List<Map<String, dynamic>> get cuisines => _cuisines;
  ProfileStats? get profileStats => _profileStats;
  Failure? get error => _error;
  bool get isLoading => _isLoading;

  /// Search restaurants
  Future<void> searchRestaurants({
    required String query,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _searchRestaurantsUseCase(
      query: query,
      latitude: latitude,
      longitude: longitude,
    );

    result.fold(
      onSuccess: (restaurants) {
        _restaurants = restaurants;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _restaurants = [];
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Get nearby restaurants
  Future<void> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getNearbyRestaurantsUseCase(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );

    result.fold(
      onSuccess: (restaurants) {
        _nearbyRestaurants = restaurants;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _nearbyRestaurants = [];
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Get all restaurants with filters
  Future<void> getRestaurants({
    int? cityId,
    int? page,
    double? latitude,
    double? longitude,
    String? search,
    int? cuisines,
    int? day,
    String? time,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getRestaurantsUseCase(
      cityId: cityId,
      page: page,
      latitude: latitude,
      longitude: longitude,
      search: search,
      cuisines: cuisines,
      day: day,
      time: time,
    );

    result.fold(
      onSuccess: (restaurants) {
        _restaurants = restaurants;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _restaurants = [];
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Get saved restaurants
  Future<void> getSavedRestaurants({
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getSavedRestaurantsUseCase(
      latitude: latitude,
      longitude: longitude,
    );

    result.fold(
      onSuccess: (restaurants) {
        _savedRestaurants = restaurants;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _savedRestaurants = [];
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Get restaurant detail by slug
  Future<void> getRestaurantDetailBySlug(
    String slug, {
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getRestaurantDetailBySlugUseCase(
      slug,
      latitude: latitude,
      longitude: longitude,
    );

    result.fold(
      onSuccess: (detail) {
        _restaurantDetail = detail;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _restaurantDetail = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Get restaurant by slug
  Future<void> getRestaurantBySlug(
    String slug, {
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getRestaurantBySlugUseCase(
      slug,
      latitude: latitude,
      longitude: longitude,
    );

    result.fold(
      onSuccess: (restaurant) {
        _restaurant = restaurant;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _restaurant = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Get cuisines
  Future<void> getCuisines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getCuisinesUseCase();

    result.fold(
      onSuccess: (cuisines) {
        _cuisines = cuisines;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _cuisines = [];
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Toggle favorite status
  Future<bool?> toggleFavourite(String slug, bool isFavourite) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _toggleFavouriteUseCase(slug, isFavourite);

    bool? newStatus;
    result.fold(
      onSuccess: (status) {
        newStatus = status;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
      },
    );

    _isLoading = false;
    notifyListeners();
    return newStatus;
  }

  /// Add review
  Future<void> addReview({
    required int restaurantId,
    required int rating,
    required String comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _addReviewUseCase(
      restaurantId: restaurantId,
      rating: rating,
      comment: comment,
    );

    result.fold(
      onSuccess: (_) {
        _error = null;
      },
      onError: (failure) {
        _error = failure;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Get profile stats
  Future<void> getProfileStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getProfileStatsUseCase();

    result.fold(
      onSuccess: (stats) {
        _profileStats = stats;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _profileStats = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Submit partner request
  Future<void> submitPartnerRequest({
    required String restaurantName,
    required String contactName,
    required String email,
    required String phone,
    required String cityName,
    String? website,
    String? comments,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _submitPartnerRequestUseCase(
      restaurantName: restaurantName,
      contactName: contactName,
      email: email,
      phone: phone,
      cityName: cityName,
      website: website,
      comments: comments,
    );

    result.fold(
      onSuccess: (_) {
        _error = null;
      },
      onError: (failure) {
        _error = failure;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Clear all state
  void clear() {
    _restaurants = [];
    _nearbyRestaurants = [];
    _savedRestaurants = [];
    _restaurantDetail = null;
    _restaurant = null;
    _cuisines = [];
    _profileStats = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
