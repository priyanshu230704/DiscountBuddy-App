import '../models/restaurant.dart';
import '../models/restaurant_detail.dart';
import '../models/review.dart';
import '../models/menu_item.dart';
import '../models/user_interactions.dart';
import '../models/deal_redemption.dart';
import '../config/api_endpoints.dart';
import 'api_service.dart';

/// Service for restaurant-related API calls
class RestaurantService {
  final ApiService _apiService = ApiService();

  // --- User Interactions ---

  Future<List<Restaurant>> getRestaurants(int cityId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.restaurants,
        queryParameters: {'city': cityId.toString()},
      );

      final List<dynamic> restaurantsJson =
          (response['results'] ?? []) as List<dynamic>;

      return restaurantsJson
          .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return _getMockRestaurants();
    }
  }

  /// Get profile statistics for the current user
  Future<ProfileStats> getProfileStats() async {
    try {
      final response = await _apiService.get(ApiEndpoints.profileStats);
      return ProfileStats.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load profile stats: ${e.toString()}');
    }
  }

  /// Create a new booking
  Future<Booking> createBooking({
    required int restaurantId,
    required DateTime bookingDate,
    required int numberOfGuests,
    String specialRequests = '',
    required String contactName,
    required String contactPhone,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.bookings,
        body: {
          'restaurant': restaurantId,
          'booking_date': bookingDate.toIso8601String(),
          'number_of_guests': numberOfGuests,
          'special_requests': specialRequests,
          'contact_name': contactName,
          'contact_phone': contactPhone,
        },
      );
      return Booking.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  /// Get user's bookings
  Future<List<Booking>> getUserBookings({String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;

      final response = await _apiService.get(
        ApiEndpoints.bookings,
        queryParameters: queryParams,
      );

      // Handle the wrapped list response
      final List<dynamic> bookingsJson = response.containsKey('results')
          ? response['results'] as List<dynamic>
          : response['data'] as List<dynamic>? ?? [];

      return bookingsJson
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load bookings: ${e.toString()}');
    }
  }

  /// Get user's deal redemptions
  Future<List<DealRedemption>> getUserDealRedemptions() async {
    try {
      final response = await _apiService.get(ApiEndpoints.dealUses);

      final List<dynamic> results =
          (response['results'] ?? response['data'] ?? []) as List<dynamic>;

      return results
          .map((json) => DealRedemption.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load deal redemptions: ${e.toString()}');
    }
  }

  /// Get detail for a specific booking
  Future<Booking> getBookingDetail(int bookingId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.bookingDetail(bookingId),
      );
      return Booking.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load booking detail: ${e.toString()}');
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(int bookingId) async {
    try {
      await _apiService.post(ApiEndpoints.cancelBooking(bookingId));
    } catch (e) {
      throw Exception('Failed to cancel booking: ${e.toString()}');
    }
  }

  /// Add a review for a restaurant
  Future<Review> addReview({
    required int restaurantId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.reviews,
        body: {
          'restaurant': restaurantId,
          'rating': rating,
          'comment': comment,
        },
      );
      return Review.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add review: ${e.toString()}');
    }
  }

  /// Toggle restaurant favourite status
  Future<bool> toggleFavourite(String slug, bool isCurrentlyFavourite) async {
    try {
      if (isCurrentlyFavourite) {
        await _apiService.delete(ApiEndpoints.toggleFavourite(slug));
        return false;
      } else {
        await _apiService.post(ApiEndpoints.toggleFavourite(slug));
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle favourite: ${e.toString()}');
    }
  }

  /// Claim/Redeem a deal
  Future<Map<String, dynamic>> claimDeal(int dealId, {String? notes}) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.claimDeal(dealId),
        body: notes != null ? {'notes': notes} : {},
      );
      return response;
    } catch (e) {
      if (e.toString().contains(
        'You have reached the maximum uses for this deal',
      )) {
        rethrow;
      }
      throw Exception('Failed to claim deal: ${e.toString()}');
    }
  }

  /// Get user's saved restaurants
  Future<List<Restaurant>> getSavedRestaurants() async {
    try {
      final response = await _apiService.get(ApiEndpoints.savedRestaurants);

      // The ApiService wraps lists in a 'data' key for consistency
      final List<dynamic> results =
          (response['data'] ?? response['results'] ?? []) as List<dynamic>;

      return results
          .map(
            (json) => convertApiRestaurantToModel(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      // Return empty list if it fails, as it might be a 404/auth error handled gracefully
      return [];
    }
  }

  // --- Restaurant Browsing ---

  /// Get nearby restaurants
  Future<List<Restaurant>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radius = 10.0, // km
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.nearbyRestaurants,
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radius': radius.toString(),
        },
      );

      // The response is a list directly, but ApiService might wrap it in 'data'
      final List<dynamic> restaurantsJson = response is List
          ? response as List<dynamic>
          : ((response as Map<String, dynamic>)['data'] ??
                    (response as Map<String, dynamic>)['results'] ??
                    [])
                as List<dynamic>;

      return restaurantsJson
          .map(
            (json) => convertApiRestaurantToModel(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      // For demo purposes, return mock data
      return _getMockRestaurants();
    }
  }

  /// Search restaurants
  Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.searchRestaurants,
        queryParameters: {'q': query},
      );

      // The response is a list directly, but ApiService might wrap it in 'data'
      final List<dynamic> restaurantsJson = response is List
          ? response as List<dynamic>
          : ((response as Map<String, dynamic>)['data'] ??
                    (response as Map<String, dynamic>)['results'] ??
                    [])
                as List<dynamic>;

      return restaurantsJson
          .map(
            (json) => convertApiRestaurantToModel(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      // For demo purposes, return mock data
      return _getMockRestaurants();
    }
  }

  /// Get restaurant by ID
  Future<Restaurant> getRestaurantById(String id) async {
    try {
      final response = await _apiService.get(ApiEndpoints.restaurantById(id));
      return Restaurant.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load restaurant');
    }
  }

  /// Get home page data for customer
  /// Returns a map with: now_open, nearby, cuisines, top_10, all_restaurants
  Future<Map<String, dynamic>> getHomeData() async {
    try {
      final response = await _apiService.get(ApiEndpoints.homeData);
      return response;
    } catch (e) {
      throw Exception('Failed to load home data: ${e.toString()}');
    }
  }

  /// Convert API restaurant format to Restaurant model
  /// API format: {id: int, name, slug, city_name, country_name, latitude: string, longitude: string, ...}
  /// Restaurant model needs: {id: string, name, description, imageUrl, address, latitude: double, ...}
  /// [cuisineMap] is an optional map of restaurant ID to cuisine name for better cuisine assignment
  Restaurant convertApiRestaurantToModel(
    Map<String, dynamic> json, {
    Map<int, String>? cuisineMap,
  }) {
    final restaurantId = json['id'] as int? ?? 0;

    // Build address from city_name and country_name
    final cityName = json['city_name'] as String? ?? '';
    final countryName = json['country_name'] as String? ?? '';
    final address = cityName.isNotEmpty && countryName.isNotEmpty
        ? '$cityName, $countryName'
        : (cityName.isNotEmpty ? cityName : 'Address not available');

    // Parse latitude and longitude
    final latStr = json['latitude'] as String? ?? '0';
    final lngStr = json['longitude'] as String? ?? '0';
    final latitude = double.tryParse(latStr) ?? 0.0;
    final longitude = double.tryParse(lngStr) ?? 0.0;

    // Image URL
    final imageUrl =
        json['primary_image'] as String? ??
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800';

    // Cuisine
    final cuisine = cuisineMap?[restaurantId] ?? 'Restaurant';
    final slug = json['slug'] as String?;

    // Rating and Reviews
    final averageRating = _parseDouble(json['average_rating']) ?? 4.0;
    final reviewsCount = _parseInt(json['reviews_count']) ?? 0;

    // Discount from active_deals
    Discount discount = Discount(
      type: 'percentage',
      percentage: 10.0,
      description: 'Special discount available',
    );

    final activeDeals = json['active_deals'] as List<dynamic>? ?? [];
    if (activeDeals.isNotEmpty) {
      final firstDeal = activeDeals.first as Map<String, dynamic>;
      final dealType = firstDeal['deal_type'] as String? ?? 'percentage';
      final discountPercentage = _parseDouble(firstDeal['discount_percentage']);
      final discountAmount = _parseDouble(firstDeal['discount_amount']);

      discount = Discount(
        type: dealType == 'percentage' ? 'percentage' : 'fixed',
        percentage: discountPercentage,
        fixedAmount: discountAmount,
        description: firstDeal['description'] as String? ?? 'Special offer',
        title: firstDeal['title'] as String?,
        id: firstDeal['id'] as int?,
      );
    }

    return Restaurant(
      id: restaurantId.toString(),
      name: json['name'] as String? ?? 'Unknown Restaurant',
      description: 'Restaurant in $cityName',
      imageUrl: imageUrl,
      address: address,
      latitude: latitude,
      longitude: longitude,
      cuisine: cuisine,
      rating: averageRating.toDouble(),
      reviewCount: reviewsCount,
      distance: _parseDouble(json['distance']) ?? 0.0,
      discount: discount,
      slug: slug,
      isFavourite: json['is_favourite'] as bool? ?? false,
      leaderboardScore: _parseDouble(json['leaderboard_score']) ?? 0.0,
    );
  }

  /// Get restaurant details by slug
  Future<Restaurant> getRestaurantBySlug(String slug) async {
    try {
      // Endpoint logic handled in ApiEndpoints
      final response = await _apiService.get(
        ApiEndpoints.restaurantDetail(slug),
      );
      return _convertDetailResponseToModel(response);
    } catch (e) {
      throw Exception('Failed to load restaurant: ${e.toString()}');
    }
  }

  /// Get full restaurant details including reviews and menu
  Future<RestaurantDetail> getRestaurantDetailBySlug(String slug) async {
    try {
      // Endpoint logic handled in ApiEndpoints
      final response = await _apiService.get(
        ApiEndpoints.restaurantDetail(slug),
      );

      final restaurant = _convertDetailResponseToModel(response);

      // Parse reviews
      final reviewsJson = response['reviews'] as List<dynamic>? ?? [];
      final reviews = reviewsJson
          .map((review) => Review.fromJson(review as Map<String, dynamic>))
          .toList();

      // Parse menu categories
      final menuCategoriesJson =
          response['menu_categories'] as List<dynamic>? ?? [];
      final menuCategories =
          menuCategoriesJson
              .map(
                (category) =>
                    MenuCategory.fromJson(category as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

      return RestaurantDetail(
        restaurant: restaurant,
        reviews: reviews,
        menuCategories: menuCategories,
      );
    } catch (e) {
      throw Exception('Failed to load restaurant detail: ${e.toString()}');
    }
  }

  /// Convert restaurant detail API response to Restaurant model
  Restaurant _convertDetailResponseToModel(Map<String, dynamic> json) {
    final restaurantId = json['id'] as int? ?? 0;

    // Parse latitude and longitude from strings
    final latStr = json['latitude'] as String? ?? '0';
    final lngStr = json['longitude'] as String? ?? '0';
    final latitude = double.tryParse(latStr) ?? 0.0;
    final longitude = double.tryParse(lngStr) ?? 0.0;

    // Get primary image from images array
    String imageUrl =
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800';
    final images = json['images'] as List<dynamic>? ?? [];
    if (images.isNotEmpty) {
      final primaryImage = images.firstWhere(
        (img) => img is Map<String, dynamic> && (img['is_primary'] == true),
        orElse: () => images.first,
      );
      if (primaryImage is Map<String, dynamic>) {
        imageUrl = primaryImage['image_url'] as String? ?? imageUrl;
      }
    }

    // Get all image URLs
    final imageUrls = images
        .where((img) => img is Map<String, dynamic> && img['image_url'] != null)
        .map((img) => (img as Map<String, dynamic>)['image_url'] as String)
        .toList();

    // Get cuisine from cuisines array
    String cuisine = 'Restaurant';
    final cuisines = json['cuisines'] as List<dynamic>? ?? [];
    if (cuisines.isNotEmpty) {
      final firstCuisine = cuisines.first as Map<String, dynamic>?;
      cuisine = firstCuisine?['name'] as String? ?? cuisine;
    }

    // Get rating and review count
    final averageRating = _parseDouble(json['average_rating']) ?? 4.0;
    final reviewsCount = _parseInt(json['reviews_count']) ?? 0;

    // Get distance if available
    final distance = _parseDouble(json['distance']) ?? 0.0;

    // Get active deals and create discount from first deal
    final activeDealsJson = json['active_deals'] as List<dynamic>? ?? [];
    final activeDeals = activeDealsJson
        .map((e) => Discount.fromJson(e as Map<String, dynamic>))
        .toList();

    Discount discount = activeDeals.isNotEmpty
        ? activeDeals.first
        : Discount(
            type: 'percentage',
            percentage: 10.0,
            description: 'Special discount available',
          );

    // Get opening hours from opening_slots
    final openingSlots = json['opening_slots'] as List<dynamic>? ?? [];
    final openingHours = <String>[];
    for (final slot in openingSlots) {
      if (slot is Map<String, dynamic>) {
        final dayName = slot['day_name'] as String? ?? '';
        final openingTime = slot['opening_time'] as String? ?? '';
        final closingTime = slot['closing_time'] as String? ?? '';
        final isClosed = slot['is_closed'] as bool? ?? false;

        if (!isClosed && openingTime.isNotEmpty && closingTime.isNotEmpty) {
          // Format time (remove seconds if present)
          final openTime = openingTime.length > 5
              ? openingTime.substring(0, 5)
              : openingTime;
          final closeTime = closingTime.length > 5
              ? closingTime.substring(0, 5)
              : closingTime;
          openingHours.add('$dayName: $openTime - $closeTime');
        }
      }
    }

    return Restaurant(
      id: restaurantId.toString(),
      name: json['name'] as String? ?? 'Unknown Restaurant',
      description: json['description'] as String? ?? '',
      imageUrl: imageUrl,
      address: json['address'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      cuisine: cuisine,
      rating: averageRating.toDouble(),
      reviewCount: reviewsCount,
      distance: distance,
      discount: discount,
      images: imageUrls,
      phoneNumber: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      openingHours: openingHours,
      requiresBooking: json['requires_booking'] as bool? ?? false,
      restrictions: const [],
      slug: json['slug'] as String?,
      priceRange: json['price_range'] as int?,
      postcode: json['postcode'] as String?,
      email: json['email'] as String?,
      isFavourite: json['is_favourite'] as bool? ?? false,
      openingSlots:
          (json['opening_slots'] as List<dynamic>?)
              ?.map((e) => OpeningSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activeDeals: activeDeals,
      leaderboardScore: _parseDouble(json['leaderboard_score']) ?? 0.0,
    );
  }

  /// Mock data for development
  List<Restaurant> _getMockRestaurants() {
    return [
      Restaurant(
        id: '1',
        name: 'Prezzo',
        description:
            'Authentic Italian cuisine in a warm, welcoming atmosphere',
        imageUrl:
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
        address: '123 High Street, London',
        latitude: 51.5074,
        longitude: -0.1278,
        cuisine: 'Italian',
        rating: 4.5,
        reviewCount: 234,
        distance: 0.5,
        slug: 'the-golden-spoon',
        discount: Discount(
          type: '2for1',
          description: '2 FOR 1 on main courses',
          validDays: ['Monday', 'Tuesday', 'Wednesday'],
        ),
        requiresBooking: true,
      ),
      Restaurant(
        id: '2',
        name: 'ASK Italian',
        description: 'Modern Italian dining with fresh pasta and pizza',
        imageUrl:
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
        address: '456 Oxford Street, London',
        latitude: 51.5155,
        longitude: -0.1419,
        cuisine: 'Italian',
        rating: 4.3,
        reviewCount: 189,
        distance: 1.2,
        slug: 'pasta-paradise',
        discount: Discount(
          type: 'percentage',
          percentage: 25,
          description: '25% OFF food and drinks',
          validDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday'],
        ),
      ),
      Restaurant(
        id: '3',
        name: 'Burger King',
        description: 'Flame-grilled burgers and crispy fries',
        imageUrl:
            'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=800',
        address: '789 Regent Street, London',
        latitude: 51.5099,
        longitude: -0.1336,
        cuisine: 'Fast Food',
        rating: 4.1,
        reviewCount: 456,
        distance: 0.8,
        slug: 'sushi-zen',
        discount: Discount(
          type: 'percentage',
          percentage: 25,
          description: '25% OFF all items',
        ),
      ),
      Restaurant(
        id: '4',
        name: 'Ed\'s Easy Diner',
        description: 'Classic American diner experience',
        imageUrl:
            'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800',
        address: '321 Piccadilly, London',
        latitude: 51.5081,
        longitude: -0.1406,
        cuisine: 'American',
        rating: 4.2,
        reviewCount: 312,
        distance: 1.5,
        slug: 'eds-easy-diner',
        discount: Discount(
          type: '2for1',
          description: '2 FOR 1 on desserts',
          validDays: ['Sunday', 'Monday'],
        ),
        requiresBooking: true,
      ),
    ];
  }

  /// Helper to safely parse a value to double
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper to safely parse a value to int
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
