import '../models/restaurant.dart';
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

