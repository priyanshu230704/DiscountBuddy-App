import 'package:flutter/foundation.dart';
import 'package:discount_buddy/core/network/api_service.dart';
import 'package:discount_buddy/features/auth/data/auth_service.dart';
import 'package:discount_buddy/core/config/api_endpoints.dart';
import 'package:http/http.dart' as http;

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

  /// Get merchant aggregate dashboard statistics
  Future<Map<String, dynamic>> getMerchantDashboardStats({int? restaurantId}) async {
    try {
      await _ensureAuthenticated();

      final queryParams = <String, String>{};
      if (restaurantId != null) {
        queryParams['restaurant_id'] = restaurantId.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.merchantDashboard,
        queryParameters: queryParams,
        type: ApiType.merchant,
      );
      
      return response;
    } catch (e) {
      throw Exception('Failed to load dashboard stats: ${e.toString()}');
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
  Future<Map<String, dynamic>> getRestaurantDetail(int restaurantId) async {
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

  /// Toggle deal status
  Future<Map<String, dynamic>> toggleDealStatus(int dealId, {String? startDate, String? endDate}) async {
    try {
      await _ensureAuthenticated();
      final body = <String, dynamic>{};
      if (startDate != null) body['start_date'] = startDate;
      if (endDate != null) body['end_date'] = endDate;

      final response = await _apiService.post(
        ApiEndpoints.toggleDealStatus(dealId),
        body: body,
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      rethrow;
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

  /// List menu items for a category
  Future<List<Map<String, dynamic>>> getMenuItems({
    int? categoryId,
    int? restaurantId,
  }) async {
    try {
      await _ensureAuthenticated();
      final queryParams = <String, String>{};
      if (categoryId != null) queryParams['category'] = categoryId.toString();
      if (restaurantId != null) queryParams['restaurant'] = restaurantId.toString();

      final response = await _apiService.get(
        ApiEndpoints.merchantMenuItems,
        queryParameters: queryParams,
        type: ApiType.merchant,
      );

      if (response['results'] != null && response['results'] is List) {
        return (response['results'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load menu items: ${e.toString()}');
    }
  }

  /// Get menu category details
  Future<Map<String, dynamic>> getMenuCategoryDetails(int id, {int? restaurantId}) async {
    try {
      await _ensureAuthenticated();
      final queryParams = <String, String>{};
      if (restaurantId != null) {
        queryParams['restaurant'] = restaurantId.toString();
      }

      return await _apiService.get(
        ApiEndpoints.merchantMenuDetail(id),
        queryParameters: queryParams,
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
        return (response['results'] as List).map((e) => e as Map<String, dynamic>).toList();
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

  /// Get redemption history for a merchant
  Future<List<Map<String, dynamic>>> getMerchantRedemptionHistory({
    int? restaurantId,
    int? limit,
  }) async {
    try {
      await _ensureAuthenticated();
      final queryParams = <String, String>{};
      if (restaurantId != null) {
        queryParams['restaurant_id'] = restaurantId.toString();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.merchantRedemptionHistory,
        queryParameters: queryParams,
        type: ApiType.merchant,
      );

      if (response['results'] != null && response['results'] is List) {
        return (response['results'] as List).map((e) => e as Map<String, dynamic>).toList();
      } else if (response is List) {
        return (response as List).map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load redemption history: ${e.toString()}');
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
        queryParams['restaurant_id'] = restaurantId.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.merchantReviews,
        queryParameters: queryParams,
        type: ApiType.merchant,
      );

      if (response['results'] != null && response['results'] is List) {
        return (response['results'] as List).map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load reviews: ${e.toString()}');
    }
  }

  /// Single booking (same [booking_date] source as the list — canonical UTC ISO for display).
  Future<Map<String, dynamic>?> getMerchantBooking(int bookingId) async {
    try {
      await _ensureAuthenticated();
      final response = await _apiService.get(
        ApiEndpoints.merchantBookingDetail(bookingId),
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      debugPrint('getMerchantBooking failed: $e');
      return null;
    }
  }

  /// View all bookings for user's restaurants
  Future<List<Map<String, dynamic>>> getMerchantBookings({
    int? restaurantId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      await _ensureAuthenticated();
      final queryParams = <String, String>{};
      if (restaurantId != null) queryParams['restaurant_id'] = restaurantId.toString();
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

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
      throw Exception('Failed to load merchant bookings: ${e.toString()}');
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
      throw Exception('Failed to review booking: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> markBookingArrived(int bookingId, String arrivalTime) async {
    try {
      await _ensureAuthenticated();
      return await _apiService.post(
        ApiEndpoints.merchantBookingArrive(bookingId),
        body: {'arrival_time': arrivalTime},
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to mark booking arrived: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> markBookingNoShow(int bookingId, String reason, String notes) async {
    try {
      await _ensureAuthenticated();
      return await _apiService.post(
        ApiEndpoints.merchantBookingNoShow(bookingId),
        body: {
          'no_show_reason': reason,
          'no_show_notes': notes,
        },
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to mark booking no-show: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingReminders() async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      
      final bookings = await getMerchantBookings(
        status: 'pending',
        startDate: now.toIso8601String().split('T').first,
        endDate: tomorrow.toIso8601String().split('T').first,
      );
      
      return bookings.where((b) {
        final dateStr = b['booking_date'];
        if (dateStr == null) return false;
        final date = DateTime.tryParse(dateStr);
        if (date == null) return false;
        return date.isAfter(now) && date.isBefore(tomorrow);
      }).toList();
    } catch (e) {
      debugPrint('Failed to fetch reminders: $e');
      return [];
    }
  }

  /// Redeem a deal using QR code data
  /// QR data format: `DEALUSE:<deal_use_id>:<redemption_code>`
  Future<Map<String, dynamic>> redeemDealByQR(
    String qrData, {
    required double price,
    required int peopleCount,
    int? restaurantId,
  }) async {
    try {
      await _ensureAuthenticated();
      final body = {
        'qr_data': qrData,
        'price': price,
        'people_count': peopleCount,
      };
      if (restaurantId != null) {
        body['restaurant_id'] = restaurantId;
      }

      final response = await _apiService.post(
        ApiEndpoints.merchantRedeemDeal,
        body: body,
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
  Future<Map<String, dynamic>> redeemDealByCode(
    String redemptionCode, {
    required double price,
    required int peopleCount,
    int? restaurantId,
  }) async {
    try {
      await _ensureAuthenticated();
      final body = {
        'redemption_code': redemptionCode,
        'price': price,
        'people_count': peopleCount,
      };
      if (restaurantId != null) {
        body['restaurant_id'] = restaurantId;
      }

      final response = await _apiService.post(
        ApiEndpoints.merchantRedeemDeal,
        body: body,
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

  /// Claim a loyalty reward using QR data
  /// QR data format: `LOYALTYREWARD:<loyalty_id>:<reward_code>`
  Future<Map<String, dynamic>> claimLoyaltyRewardByQR(String qrData) async {
    try {
      await _ensureAuthenticated();
      final response = await _apiService.post(
        ApiEndpoints.merchantClaimLoyaltyReward,
        body: {'qr_data': qrData},
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Loyalty claim failed: ${e.message}');
      }
      throw Exception('Loyalty claim failed: ${e.toString()}');
    }
  }

  /// Claim a loyalty reward using a manual 6-digit reward code
  Future<Map<String, dynamic>> claimLoyaltyRewardByCode(
    String rewardCode,
  ) async {
    try {
      await _ensureAuthenticated();
      final response = await _apiService.post(
        ApiEndpoints.merchantClaimLoyaltyReward,
        body: {'reward_code': rewardCode},
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      if (e is ApiException) {
        throw Exception('Loyalty claim failed: ${e.message}');
      }
      throw Exception('Loyalty claim failed: ${e.toString()}');
    }
  }



  /// Update restaurant occupancy status
  Future<Map<String, dynamic>> updateOccupancy(int restaurantId, String occupancy) async {
    try {
      await _ensureAuthenticated();
      final response = await _apiService.patch(
        ApiEndpoints.merchantUpdateOccupancy,
        body: {'restaurant_id': restaurantId, 'occupancy': occupancy},
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to update occupancy: ${e.toString()}');
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

  /// Get reference data - Facilities (public endpoint, no auth required)
  Future<List<Map<String, dynamic>>> getFacilities({
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _apiService.get(
        ApiEndpoints.facilityList,
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
      throw Exception('Failed to load facilities: ${e.toString()}');
    }
  }

  /// Get reference data - Cuisines (public endpoint)
  Future<List<Map<String, dynamic>>> getCuisines({
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _apiService.get(
        ApiEndpoints.cuisines,
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
      throw Exception('Failed to load cuisines: ${e.toString()}');
    }
  }

  /// --- Image Management ---

  /// Upload restaurant image
  Future<Map<String, dynamic>> uploadRestaurantImage({
    required int restaurantId,
    required String imagePath,
    required String imageType, // gallery, menu
    String? altText,
    bool isPrimary = false,
  }) async {
    try {
      await _ensureAuthenticated();

      final fields = {
        'restaurant': restaurantId.toString(),
        'image_type': imageType,
        'is_primary': isPrimary.toString(),
      };
      if (altText != null) fields['alt_text'] = altText;

      final file = await http.MultipartFile.fromPath('image', imagePath);

      return await _apiService.postMultipart(
        ApiEndpoints.merchantRestaurantImages,
        fields: fields,
        files: {'image': file},
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Delete restaurant image
  Future<void> deleteRestaurantImage(int imageId) async {
    try {
      await _ensureAuthenticated();
      await _apiService.delete(
        ApiEndpoints.merchantRestaurantImageDetail(imageId),
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to delete image: ${e.toString()}');
    }
  }

  /// Set primary image for restaurant gallery
  Future<Map<String, dynamic>> setPrimaryImage(int imageId) async {
    try {
      await _ensureAuthenticated();
      return await _apiService.patch(
        ApiEndpoints.merchantRestaurantImageDetail(imageId),
        body: {'is_primary': true},
        type: ApiType.merchant,
      );
    } catch (e) {
      throw Exception('Failed to set primary image: ${e.toString()}');
    }
  }

  /// Get full analytics data for the merchant dashboard
  Future<Map<String, dynamic>> getMerchantAnalytics({
    int? restaurantId,
    int period = 30,
  }) async {
    try {
      await _ensureAuthenticated();
      final queryParams = <String, String>{};
      queryParams['period'] = period.toString();
      if (restaurantId != null) {
        queryParams['restaurant_id'] = restaurantId.toString();
      }
      final response = await _apiService.get(
        ApiEndpoints.merchantAnalytics,
        queryParameters: queryParams,
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to load analytics: ${e.toString()}');
    }
  }

  /// List customers participating in the restaurant's loyalty program
  Future<Map<String, dynamic>> getLoyaltyCustomers({
    required int restaurantId,
    bool? eligibleOnly,
  }) async {
    try {
      await _ensureAuthenticated();
      final queryParams = <String, String>{
        'restaurant_id': restaurantId.toString(),
      };
      if (eligibleOnly != null) {
        queryParams['eligible_only'] = eligibleOnly.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.merchantLoyaltyCustomers,
        queryParameters: queryParams,
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to load loyalty customers: ${e.toString()}');
    }
  }

  /// Mark customer's loyalty reward as claimed
  Future<Map<String, dynamic>> claimLoyaltyReward({
    required int restaurantId,
    required int userId,
  }) async {
    try {
      await _ensureAuthenticated();
      final response = await _apiService.post(
        ApiEndpoints.merchantClaimReward,
        body: {
          'restaurant_id': restaurantId,
          'user_id': userId,
        },
        type: ApiType.merchant,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to claim loyalty reward: ${e.toString()}');
    }
  }

  /// Retrieve loyalty redemption and claim history
  Future<List<Map<String, dynamic>>> getLoyaltyHistory({
    required int restaurantId,
    int? userId,
    String? status,
  }) async {
    try {
      await _ensureAuthenticated();
      final queryParams = <String, String>{
        'restaurant_id': restaurantId.toString(),
      };
      if (userId != null) {
        queryParams['user_id'] = userId.toString();
      }
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        ApiEndpoints.merchantLoyaltyHistory,
        queryParameters: queryParams,
        type: ApiType.merchant,
      );

      if (response['records'] != null && response['records'] is List) {
        return (response['records'] as List).cast<Map<String, dynamic>>();
      } else if (response['results'] != null && response['results'] is List) {
        return (response['results'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load loyalty history: ${e.toString()}');
    }
  }
}

