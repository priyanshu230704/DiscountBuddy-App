import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/api_endpoints.dart';

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
    int? cityId,
  }) async {
    try {
      await _ensureAuthenticated();

      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (cityId != null) queryParams['city'] = cityId.toString();

      final response = await _apiService.get(
        ApiEndpoints.merchantRestaurants,
        queryParameters: queryParams,
        type: ApiType.merchant,
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
        ApiEndpoints.merchantRestaurantDetail(restaurantId),
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to load restaurant: ${e.toString()}');
    }
  }

  /// Create restaurant - returns raw Map
  Future<Map<String, dynamic>> createRestaurant(
    Map<String, dynamic> restaurantData,
  ) async {
    try {
      await _ensureAuthenticated();

      final response = await _apiService.post(
        ApiEndpoints.merchantRestaurants,
        body: restaurantData,
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Failed to create restaurant: ${e.message}');
      }
      throw Exception('Failed to create restaurant: ${e.toString()}');
    }
  }

  /// Update restaurant - returns raw Map
  Future<Map<String, dynamic>> updateRestaurant(
    int restaurantId,
    Map<String, dynamic> restaurantData,
  ) async {
    try {
      await _ensureAuthenticated();

      final response = await _apiService.patch(
        ApiEndpoints.merchantRestaurantDetail(restaurantId),
        body: restaurantData,
        type: ApiType.merchant,
      );
      return response;
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

      await _apiService.delete(
        ApiEndpoints.merchantRestaurantDetail(restaurantId),
        type: ApiType.merchant,
      );
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
      if (restaurantId != null) {
        queryParams['restaurant'] = restaurantId.toString();
      }
      if (dealType != null) queryParams['deal_type'] = dealType;
      if (isFeatured != null) {
        queryParams['is_featured'] = isFeatured.toString();
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _apiService.get(
        ApiEndpoints.merchantDeals,
        queryParameters: queryParams,
        type: ApiType.merchant,
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
        ApiEndpoints.merchantDealDetail(dealId),
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to load deal: ${e.toString()}');
    }
  }

  /// Create deal
  Future<Map<String, dynamic>> createDeal(Map<String, dynamic> dealData) async {
    try {
      await _ensureAuthenticated();

      final response = await _apiService.post(
        ApiEndpoints.merchantDeals,
        body: dealData,
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Failed to create deal: ${e.message}');
      }
      throw Exception('Failed to create deal: ${e.toString()}');
    }
  }

  /// Update deal
  Future<Map<String, dynamic>> updateDeal(
    int dealId,
    Map<String, dynamic> dealData,
  ) async {
    try {
      await _ensureAuthenticated();

      final response = await _apiService.patch(
        ApiEndpoints.merchantDealDetail(dealId),
        body: dealData,
        type: ApiType.merchant,
      );
      return response;
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

      await _apiService.delete(
        ApiEndpoints.merchantDealDetail(dealId),
        type: ApiType.merchant,
      );
      // 204 No Content response is expected
      return;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Failed to delete deal: ${e.message}');
      }
      throw Exception('Failed to delete deal: ${e.toString()}');
    }
  }

  /// --- Menu Management ---

  /// List menu categories for merchant's restaurants
  Future<List<Map<String, dynamic>>> getMenuCategories({
    int? restaurantId,
  }) async {
    try {
      await _ensureAuthenticated();
      final queryParams = <String, String>{};
      if (restaurantId != null) {
        queryParams['restaurant'] = restaurantId.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.merchantMenu,
        queryParameters: queryParams,
        type: ApiType.merchant,
      );

      if (response['results'] != null && response['results'] is List) {
        return (response['results'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load menu categories: ${e.toString()}');
    }
  }

  /// Get menu category details
  Future<Map<String, dynamic>> getMenuCategoryDetails(int id) async {
    try {
      await _ensureAuthenticated();
      return await _apiService.get(
        ApiEndpoints.merchantMenuDetail(id),
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to load menu category: ${e.toString()}');
    }
  }

  /// Create menu category
  Future<Map<String, dynamic>> createMenuCategory(
    Map<String, dynamic> data,
  ) async {
    try {
      await _ensureAuthenticated();
      return await _apiService.post(
        ApiEndpoints.merchantMenu,
        body: data,
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to create menu category: ${e.toString()}');
    }
  }

  /// Update menu category
  Future<Map<String, dynamic>> updateMenuCategory(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _ensureAuthenticated();
      return await _apiService.patch(
        ApiEndpoints.merchantMenuDetail(id),
        body: data,
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to update menu category: ${e.toString()}');
    }
  }

  /// Create menu item
  Future<Map<String, dynamic>> createMenuItem(Map<String, dynamic> data) async {
    try {
      await _ensureAuthenticated();
      return await _apiService.post(
        ApiEndpoints.merchantMenuItems,
        body: data,
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to create menu item: ${e.toString()}');
    }
  }

  /// Update menu item
  Future<Map<String, dynamic>> updateMenuItem(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _ensureAuthenticated();
      return await _apiService.patch(
        ApiEndpoints.merchantMenuItemDetail(id),
        body: data,
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to update menu item: ${e.toString()}');
    }
  }

  /// Delete menu item
  Future<void> deleteMenuItem(int id) async {
    try {
      await _ensureAuthenticated();
      await _apiService.delete(
        ApiEndpoints.merchantMenuItemDetail(id),
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to delete menu item: ${e.toString()}');
    }
  }

  /// Delete menu category
  Future<void> deleteMenuCategory(int id) async {
    try {
      await _ensureAuthenticated();
      await _apiService.delete(
        ApiEndpoints.merchantMenuDetail(id),
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to delete menu category: ${e.toString()}');
    }
  }

  /// --- Opening Slots Management ---

  /// List opening slots
  Future<List<Map<String, dynamic>>> getOpeningSlots({
    int? restaurantId,
  }) async {
    try {
      await _ensureAuthenticated();
      final queryParams = <String, String>{};
      if (restaurantId != null) {
        queryParams['restaurant'] = restaurantId.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.merchantOpeningSlots,
        queryParameters: queryParams,
        type: ApiType.merchant,
      );

      if (response['results'] != null && response['results'] is List) {
        return (response['results'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load opening slots: ${e.toString()}');
    }
  }

  /// Create opening slot
  Future<Map<String, dynamic>> createOpeningSlot(
    Map<String, dynamic> data,
  ) async {
    try {
      await _ensureAuthenticated();
      return await _apiService.post(
        ApiEndpoints.merchantOpeningSlots,
        body: data,
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to create opening slot: ${e.toString()}');
    }
  }

  /// --- Merchant Insights (Reviews & Bookings) ---

  /// View all reviews for user's restaurants
  Future<List<Map<String, dynamic>>> getMerchantReviews({
    int? restaurantId,
  }) async {
    try {
      await _ensureAuthenticated();
      final queryParams = <String, String>{};
      if (restaurantId != null) {
        queryParams['restaurant'] = restaurantId.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.merchantReviews,
        queryParameters: queryParams,
        type: ApiType.merchant,
      );

      if (response['results'] != null && response['results'] is List) {
        return (response['results'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load reviews: ${e.toString()}');
    }
  }

  /// View all bookings for user's restaurants
  Future<List<Map<String, dynamic>>> getMerchantBookings({
    int? restaurantId,
    String? status,
  }) async {
    try {
      await _ensureAuthenticated();
      final queryParams = <String, String>{};
      if (restaurantId != null) {
        queryParams['restaurant'] = restaurantId.toString();
      }
      if (status != null) queryParams['status'] = status;

      final response = await _apiService.get(
        ApiEndpoints.merchantBookings,
        queryParameters: queryParams,
        type: ApiType.merchant,
      );

      if (response['results'] != null && response['results'] is List) {
        return (response['results'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load bookings: ${e.toString()}');
    }
  }

  /// Review booking (Confirm/Reject)
  Future<Map<String, dynamic>> reviewBooking(
    int bookingId,
    String status,
  ) async {
    try {
      await _ensureAuthenticated();
      return await _apiService.patch(
        ApiEndpoints.merchantBookingDetail(bookingId),
        body: {'status': status},
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to update booking: ${e.toString()}');
    }
  }

  /// Redeem a deal using QR code data
  /// QR data format: DEALUSE:<deal_use_id>:<redemption_code>
  Future<Map<String, dynamic>> redeemDealByQR(String qrData) async {
    try {
      await _ensureAuthenticated();
      final response = await _apiService.post(
        ApiEndpoints.merchantRedeemDeal,
        body: {'qr_data': qrData},
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Redemption failed: ${e.message}');
      }
      throw Exception('Redemption failed: ${e.toString()}');
    }
  }

  /// Redeem a deal using manual redemption code
  Future<Map<String, dynamic>> redeemDealByCode(String redemptionCode) async {
    try {
      await _ensureAuthenticated();
      final response = await _apiService.post(
        ApiEndpoints.merchantRedeemDeal,
        body: {'redemption_code': redemptionCode},
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Redemption failed: ${e.message}');
      }
      throw Exception('Redemption failed: ${e.toString()}');
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
        ApiEndpoints.cities,
        queryParameters: queryParams,
        type: ApiType.common,
      );

      if (response.containsKey('results')) {
        final results = response['results'];
        if (results is List) {
          return (results).map((item) => item as Map<String, dynamic>).toList();
        }
      } else if (response is List) {
        return (response as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
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
        ApiEndpoints.categories,
        queryParameters: queryParams,
        type: ApiType.common,
      );

      if (response.containsKey('results')) {
        final results = response['results'];
        if (results is List) {
          return (results).map((item) => item as Map<String, dynamic>).toList();
        }
      } else if (response is List) {
        return (response as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load categories: ${e.toString()}');
    }
  }
}
