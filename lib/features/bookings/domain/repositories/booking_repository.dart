import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';

/// Intent-based booking repository — customer-facing operations.
abstract class BookingRepository {
  /// Create a new booking for the customer
  Future<Result<Booking>> createBooking({
    required int restaurantId,
    required DateTime bookingDate,
    required int numberOfGuests,
    String? specialRequests,
    String? contactName,
    String? contactPhone,
  });

  /// Get user's booking history
  Future<Result<List<Booking>>> listUserBookings({String? status});

  /// Update an existing booking (customer)
  Future<Result<Booking>> updateBooking({
    required int bookingId,
    DateTime? bookingDate,
    int? numberOfGuests,
    String? specialRequests,
    String? contactName,
    String? contactPhone,
  });

  /// Delete a booking
  Future<Result<void>> deleteBooking(int bookingId);

  /// Cancel a booking
  Future<Result<void>> cancelBooking(int bookingId);
}
