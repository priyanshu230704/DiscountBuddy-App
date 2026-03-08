import '../config/api_endpoints.dart';
import 'api_service.dart';

class BookingService {
  final ApiService _apiService = ApiService();

  Future<void> _ensureAuthenticated() async {
    if (_apiService.authToken == null) {
      throw Exception('User is not authenticated');
    }
  }

  // --- Customer Booking Flow ---

  /// Create a booking (User)
  Future<Map<String, dynamic>> createBooking({
    required int restaurantId,
    required DateTime bookingDate,
    required int numberOfGuests,
    String? specialRequests,
    String? contactName,
    String? contactPhone,
  }) async {
    await _ensureAuthenticated();

    final data = {
      'restaurant': restaurantId,
      'booking_date': bookingDate.toIso8601String(),
      'number_of_guests': numberOfGuests,
      'special_requests': ?specialRequests,
      'contact_name': ?contactName,
      'contact_phone': ?contactPhone,
    };

    return await _apiService.post(
      ApiEndpoints.bookings,
      body: data,
      type: ApiType.user,
    );
  }

  /// Get user's booking history
  Future<List<Map<String, dynamic>>> getUserBookings({String? status}) async {
    await _ensureAuthenticated();

    final queryParams = <String, String>{};
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _apiService.get(
      ApiEndpoints.bookings,
      queryParameters: queryParams,
      type: ApiType.user,
    );

    if (response['data'] != null && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else if (response.containsKey('results') && response['results'] is List) {
      // Handle pagination result if applicable
      return List<Map<String, dynamic>>.from(response['results']);
    }

    return [];
  }

  /// Cancel a booking (User)
  Future<void> cancelBooking(int bookingId) async {
    await _ensureAuthenticated();
    await _apiService.post(
      ApiEndpoints.cancelBooking(bookingId),
      type: ApiType.user,
    );
  }

  // --- Merchant Booking Flow ---

  /// Get merchant's bookings
  Future<List<Map<String, dynamic>>> getMerchantBookings({
    String? status,
  }) async {
    await _ensureAuthenticated();

    final queryParams = <String, String>{};
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _apiService.get(
      ApiEndpoints.merchantBookings,
      queryParameters: queryParams,
      type: ApiType.merchant,
    );

    if (response['results'] != null && response['results'] is List) {
      return List<Map<String, dynamic>>.from(response['results']);
    } else if (response['data'] != null && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    }

    return [];
  }
}
