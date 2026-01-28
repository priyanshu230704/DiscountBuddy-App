import '../models/restaurant.dart';
import '../models/restaurant_detail.dart';
import '../models/review.dart';
import '../models/menu_item.dart';
import 'api_service.dart';

/// Service for restaurant-related API calls
class RestaurantService {
  final ApiService _apiService = ApiService();

  /// Get nearby restaurants
  Future<List<Restaurant>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radius = 10.0, // km
  }) async {
    try {
      final response = await _apiService.get(
        '/restaurants/nearby',
        queryParameters: {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
          'radius': radius.toString(),
        },
      );

      final List<dynamic> restaurantsJson = response['data'] as List<dynamic>;
      return restaurantsJson
          .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
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
        '/restaurants/search',
        queryParameters: {'q': query},
      );

      final List<dynamic> restaurantsJson = response['data'] as List<dynamic>;
      return restaurantsJson
          .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // For demo purposes, return mock data
      return _getMockRestaurants();
    }
  }

  /// Get restaurant by ID
  Future<Restaurant> getRestaurantById(String id) async {
    try {
      final response = await _apiService.get('/restaurants/$id');
      return Restaurant.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load restaurant');
    }
  }

  /// Get home page data for customer
  /// Returns a map with: now_open, nearby, cuisines, top_10, all_restaurants
  Future<Map<String, dynamic>> getHomeData() async {
    try {
      final response = await _apiService.get('/restaurants/home/');
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

    // Parse latitude and longitude from strings
    final latStr = json['latitude'] as String? ?? '0';
    final lngStr = json['longitude'] as String? ?? '0';
    final latitude = double.tryParse(latStr) ?? 0.0;
    final longitude = double.tryParse(lngStr) ?? 0.0;

    // Get image URL - use primary_image if available, otherwise placeholder
    final imageUrl = json['primary_image'] as String? ??
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800';

    // Get cuisine from map if available, otherwise use default
    final cuisine = cuisineMap?[restaurantId] ?? 'Restaurant';

    // Get slug if available
    final slug = json['slug'] as String?;

    // Create a default discount since API doesn't provide it
    final discount = Discount(
      type: 'percentage',
      percentage: 10.0,
      description: 'Special discount available',
    );

    return Restaurant(
      id: restaurantId.toString(),
      name: json['name'] as String? ?? 'Unknown Restaurant',
      description: 'Restaurant in $cityName',
      imageUrl: imageUrl,
      address: address,
      latitude: latitude,
      longitude: longitude,
      cuisine: cuisine,
      rating: 4.0, // Default rating since API doesn't provide
      reviewCount: 0, // Default review count
      distance: 0.0, // Will be calculated if needed
      discount: discount,
      slug: slug,
    );
  }

  /// Get restaurant details by slug
  Future<Restaurant> getRestaurantBySlug(String slug) async {
    try {
      // Remove any trailing slashes from slug and ensure endpoint doesn't have trailing slash
      final cleanSlug = slug.trim().replaceAll(RegExp(r'/+$'), '');
      final endpoint = '/restaurants/restaurant-detail/$cleanSlug';
      final response = await _apiService.get(endpoint);
      return _convertDetailResponseToModel(response);
    } catch (e) {
      throw Exception('Failed to load restaurant: ${e.toString()}');
    }
  }

  /// Get full restaurant details including reviews and menu
  Future<RestaurantDetail> getRestaurantDetailBySlug(String slug) async {
    try {
      // Remove any trailing slashes from slug and ensure endpoint doesn't have trailing slash
      final cleanSlug = slug.trim().replaceAll(RegExp(r'/+$'), '');
      final endpoint = '/restaurants/restaurant-detail/$cleanSlug';
      final response = await _apiService.get(endpoint);
      
      final restaurant = _convertDetailResponseToModel(response);
      
      // Parse reviews
      final reviewsJson = response['reviews'] as List<dynamic>? ?? [];
      final reviews = reviewsJson
          .map((review) => Review.fromJson(review as Map<String, dynamic>))
          .toList();
      
      // Parse menu categories
      final menuCategoriesJson = response['menu_categories'] as List<dynamic>? ?? [];
      final menuCategories = menuCategoriesJson
          .map((category) => MenuCategory.fromJson(category as Map<String, dynamic>))
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
    String imageUrl = 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800';
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
    final averageRating = json['average_rating'] as num? ?? 4.0;
    final reviewsCount = json['reviews_count'] as int? ?? 0;

    // Get distance if available
    final distance = json['distance'] != null 
        ? (json['distance'] as num).toDouble() 
        : 0.0;

    // Get active deals and create discount from first deal
    final activeDeals = json['active_deals'] as List<dynamic>? ?? [];
    Discount discount = Discount(
      type: 'percentage',
      percentage: 10.0,
      description: 'Special discount available',
    );
    
    if (activeDeals.isNotEmpty) {
      final firstDeal = activeDeals.first as Map<String, dynamic>;
      final dealType = firstDeal['deal_type'] as String? ?? 'percentage';
      final discountPercentage = firstDeal['discount_percentage'] as num?;
      final discountAmount = firstDeal['discount_amount'] as num?;
      final dealDescription = firstDeal['description'] as String? ?? 'Special offer';
      
      discount = Discount(
        type: dealType == 'percentage' ? 'percentage' : 'fixed',
        percentage: discountPercentage?.toDouble(),
        fixedAmount: discountAmount?.toDouble(),
        description: dealDescription,
      );
    }

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
      requiresBooking: false, // API doesn't provide this
      restrictions: const [], // API doesn't provide this
      slug: json['slug'] as String?,
      priceRange: json['price_range'] as int?,
      postcode: json['postcode'] as String?,
      email: json['email'] as String?,
    );
  }

  /// Mock data for development
  List<Restaurant> _getMockRestaurants() {
    return [
      Restaurant(
        id: '1',
        name: 'Prezzo',
        description: 'Authentic Italian cuisine in a warm, welcoming atmosphere',
        imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
        address: '123 High Street, London',
        latitude: 51.5074,
        longitude: -0.1278,
        cuisine: 'Italian',
        rating: 4.5,
        reviewCount: 234,
        distance: 0.5,
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
        imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
        address: '456 Oxford Street, London',
        latitude: 51.5155,
        longitude: -0.1419,
        cuisine: 'Italian',
        rating: 4.3,
        reviewCount: 189,
        distance: 1.2,
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
        imageUrl: 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=800',
        address: '789 Regent Street, London',
        latitude: 51.5099,
        longitude: -0.1336,
        cuisine: 'Fast Food',
        rating: 4.1,
        reviewCount: 456,
        distance: 0.8,
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
        imageUrl: 'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800',
        address: '321 Piccadilly, London',
        latitude: 51.5081,
        longitude: -0.1406,
        cuisine: 'American',
        rating: 4.2,
        reviewCount: 312,
        distance: 1.5,
        discount: Discount(
          type: '2for1',
          description: '2 FOR 1 on desserts',
          validDays: ['Sunday', 'Monday'],
        ),
        requiresBooking: true,
      ),
    ];
  }
}

