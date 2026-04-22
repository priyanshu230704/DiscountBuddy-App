import '../config/api_endpoints.dart';
import '../utils/date_time_utils.dart';
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
      'booking_date': DateTimeUtils.toApiUtcIso(bookingDate),
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

  /// Update a booking (User) - PATCH
  Future<Map<String, dynamic>> updateBooking({
    required int bookingId,
    DateTime? bookingDate,
    int? numberOfGuests,
    String? specialRequests,
    String? contactName,
    String? contactPhone,
  }) async {
    await _ensureAuthenticated();

    final data = <String, dynamic>{};
    if (bookingDate != null) {
      data['booking_date'] = DateTimeUtils.toApiUtcIso(bookingDate);
    }
    if (numberOfGuests != null) data['number_of_guests'] = numberOfGuests;
    if (specialRequests != null) data['special_requests'] = specialRequests;
    if (contactName != null) data['contact_name'] = contactName;
    if (contactPhone != null) data['contact_phone'] = contactPhone;

    return await _apiService.patch(
      ApiEndpoints.bookingDetail(bookingId),
      body: data,
      type: ApiType.user,
    );
  }

  /// Delete a booking (User) - DELETE
  Future<void> deleteBooking(int bookingId) async {
    await _ensureAuthenticated();
    await _apiService.delete(
      ApiEndpoints.bookingDetail(bookingId),
      type: ApiType.user,
    );
  }

  /// Cancel a booking (User) - POST (Legacy/Alternative)
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
