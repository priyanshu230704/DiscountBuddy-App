import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Merchant Service for restaurant and deal management
class MerchantService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  /// Ensure auth token is set before making API calls
  Future<void> _ensureAuthenticated() async {
    // Check if token is already set
    if (_apiService.authToken != null) {
      return;
    }
    
    // Try to load token from storage
    final token = await _authService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      _apiService.setAuthToken(token);
    } else {
      throw Exception('Authentication required. Please login again.');
    }
  }

  /// List merchant's restaurants - returns raw API response as List<Map>
  Future<List<Map<String, dynamic>>> getMerchantRestaurants({
    int? page,
    String? search,
    String? ordering,
  }) async {
    try {
      await _ensureAuthenticated();
      
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _apiService.get(
        '/restaurants/merchant/restaurants/',
        queryParameters: queryParams,
      );

      if (response['results'] != null && response['results'] is List) {
        final results = response['results'] as List;
        return results.map((json) => json as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load restaurants: ${e.toString()}');
    }
  }

  /// Get restaurant details - returns raw Map for form compatibility
  Future<Map<String, dynamic>> getRestaurantDetails(int restaurantId) async {
    try {
      await _ensureAuthenticated();
      
      final response = await _apiService.get(
        '/restaurants/merchant/restaurants/$restaurantId/',
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load restaurant: ${e.toString()}');
    }
  }

  /// Create restaurant - returns raw Map
  Future<Map<String, dynamic>> createRestaurant(Map<String, dynamic> restaurantData) async {
    try {
      await _ensureAuthenticated();
      
      final response = await _apiService.post(
        '/restaurants/merchant/restaurants/',
        body: restaurantData,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Failed to create restaurant: ${e.message}');
      }
      throw Exception('Failed to create restaurant: ${e.toString()}');
    }
  }

  /// Update restaurant - returns raw Map
  Future<Map<String, dynamic>> updateRestaurant(int restaurantId, Map<String, dynamic> restaurantData) async {
    try {
      await _ensureAuthenticated();
      
      final response = await _apiService.patch(
        '/restaurants/merchant/restaurants/$restaurantId/',
        body: restaurantData,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Failed to update restaurant: ${e.message}');
      }
      throw Exception('Failed to update restaurant: ${e.toString()}');
    }
  }

  /// Delete restaurant
  Future<void> deleteRestaurant(int restaurantId) async {
    try {
      await _ensureAuthenticated();
      
      await _apiService.delete('/restaurants/merchant/restaurants/$restaurantId/');
      // 204 No Content response is expected
      return;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Failed to delete restaurant: ${e.message}');
      }
      throw Exception('Failed to delete restaurant: ${e.toString()}');
    }
  }

  /// List merchant's deals
  Future<List<Map<String, dynamic>>> getMerchantDeals({
    int? page,
    int? restaurantId,
    String? dealType,
    bool? isFeatured,
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (restaurantId != null) queryParams['restaurant'] = restaurantId.toString();
      if (dealType != null) queryParams['deal_type'] = dealType;
      if (isFeatured != null) queryParams['is_featured'] = isFeatured.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _apiService.get(
        '/restaurants/merchant/deals/',
        queryParameters: queryParams,
      );

      if (response['results'] != null && response['results'] is List) {
        return (response['results'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load deals: ${e.toString()}');
    }
  }

  /// Get deal details
  Future<Map<String, dynamic>> getDealDetails(int dealId) async {
    try {
      await _ensureAuthenticated();
      
      final response = await _apiService.get(
        '/restaurants/merchant/deals/$dealId/',
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load deal: ${e.toString()}');
    }
  }

  /// Create deal
  Future<Map<String, dynamic>> createDeal(Map<String, dynamic> dealData) async {
    try {
      await _ensureAuthenticated();
      
      final response = await _apiService.post(
        '/restaurants/merchant/deals/',
        body: dealData,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Failed to create deal: ${e.message}');
      }
      throw Exception('Failed to create deal: ${e.toString()}');
    }
  }

  /// Update deal
  Future<Map<String, dynamic>> updateDeal(int dealId, Map<String, dynamic> dealData) async {
    try {
      await _ensureAuthenticated();
      
      final response = await _apiService.patch(
        '/restaurants/merchant/deals/$dealId/',
        body: dealData,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Failed to update deal: ${e.message}');
      }
      throw Exception('Failed to update deal: ${e.toString()}');
    }
  }

  /// Delete deal
  Future<void> deleteDeal(int dealId) async {
    try {
      await _ensureAuthenticated();
      
      await _apiService.delete('/restaurants/merchant/deals/$dealId/');
      // 204 No Content response is expected
      return;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Failed to delete deal: ${e.message}');
      }
      throw Exception('Failed to delete deal: ${e.toString()}');
    }
  }

  /// Get reference data - Cities
  Future<List<Map<String, dynamic>>> getCities({
    int? countryId,
    bool? isActive,
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (countryId != null) queryParams['country'] = countryId.toString();
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _apiService.get(
        '/restaurants/cities/',
        queryParameters: queryParams,
      );

      if (response.containsKey('results')) {
        final results = response['results'];
        if (results is List) {
          return (results as List).map((item) => item as Map<String, dynamic>).toList();
        }
      } else if (response is List) {
        return (response as List).map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load cities: ${e.toString()}');
    }
  }

  /// Get reference data - Categories (public endpoint, no auth required)
  Future<List<Map<String, dynamic>>> getCategories({
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _apiService.get(
        '/restaurants/categories/',
        queryParameters: queryParams,
      );

      if (response.containsKey('results')) {
        final results = response['results'];
        if (results is List) {
          return (results as List).map((item) => item as Map<String, dynamic>).toList();
        }
      } else if (response is List) {
        return (response as List).map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load categories: ${e.toString()}');
    }
  }
}
