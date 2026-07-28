import 'package:discount_buddy/core/domain/error_mapper.dart';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/bookings/data/booking_service.dart';
import 'package:discount_buddy/features/bookings/domain/repositories/booking_repository.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({BookingService? service})
    : _service = service ?? BookingService();

  final BookingService _service;

  @override
  Future<Result<Booking>> createBooking({
    required int restaurantId,
    required DateTime bookingDate,
    required int numberOfGuests,
    String? specialRequests,
    String? contactName,
    String? contactPhone,
  }) async {
    try {
      final result = await _service.createBooking(
        restaurantId: restaurantId,
        bookingDate: bookingDate,
        numberOfGuests: numberOfGuests,
        specialRequests: specialRequests,
        contactName: contactName,
        contactPhone: contactPhone,
      );
      return Success(Booking.fromJson(result));
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Failed to create booking'));
    }
  }

  @override
  Future<Result<List<Booking>>> listUserBookings({String? status}) async {
    try {
      final results = await _service.getUserBookings(status: status);
      final bookings = results
          .map((json) => Booking.fromJson(json))
          .toList();
      return Success(bookings);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Failed to load bookings'));
    }
  }

  @override
  Future<Result<Booking>> updateBooking({
    required int bookingId,
    DateTime? bookingDate,
    int? numberOfGuests,
    String? specialRequests,
    String? contactName,
    String? contactPhone,
  }) async {
    try {
      final result = await _service.updateBooking(
        bookingId: bookingId,
        bookingDate: bookingDate,
        numberOfGuests: numberOfGuests,
        specialRequests: specialRequests,
        contactName: contactName,
        contactPhone: contactPhone,
      );
      return Success(Booking.fromJson(result));
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Failed to update booking'));
    }
  }

  @override
  Future<Result<void>> deleteBooking(int bookingId) async {
    try {
      await _service.deleteBooking(bookingId);
      return const Success(null);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Failed to delete booking'));
    }
  }

  @override
  Future<Result<void>> cancelBooking(int bookingId) async {
    try {
      await _service.cancelBooking(bookingId);
      return const Success(null);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Failed to cancel booking'));
    }
  }
}
