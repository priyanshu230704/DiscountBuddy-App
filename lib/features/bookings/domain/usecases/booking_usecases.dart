import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/bookings/domain/repositories/booking_repository.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';

class CreateBookingUseCase {
  CreateBookingUseCase(this._repository);

  final BookingRepository _repository;

  Future<Result<Booking>> call({
    required int restaurantId,
    required DateTime bookingDate,
    required int numberOfGuests,
    String? specialRequests,
    String? contactName,
    String? contactPhone,
  }) async {
    return await _repository.createBooking(
      restaurantId: restaurantId,
      bookingDate: bookingDate,
      numberOfGuests: numberOfGuests,
      specialRequests: specialRequests,
      contactName: contactName,
      contactPhone: contactPhone,
    );
  }
}

class ListUserBookingsUseCase {
  ListUserBookingsUseCase(this._repository);

  final BookingRepository _repository;

  Future<Result<List<Booking>>> call({String? status}) async {
    return await _repository.listUserBookings(status: status);
  }
}

class UpdateBookingUseCase {
  UpdateBookingUseCase(this._repository);

  final BookingRepository _repository;

  Future<Result<Booking>> call({
    required int bookingId,
    DateTime? bookingDate,
    int? numberOfGuests,
    String? specialRequests,
    String? contactName,
    String? contactPhone,
  }) async {
    return await _repository.updateBooking(
      bookingId: bookingId,
      bookingDate: bookingDate,
      numberOfGuests: numberOfGuests,
      specialRequests: specialRequests,
      contactName: contactName,
      contactPhone: contactPhone,
    );
  }
}

class DeleteBookingUseCase {
  DeleteBookingUseCase(this._repository);

  final BookingRepository _repository;

  Future<Result<void>> call(int bookingId) async {
    return await _repository.deleteBooking(bookingId);
  }
}

class CancelBookingUseCase {
  CancelBookingUseCase(this._repository);

  final BookingRepository _repository;

  Future<Result<void>> call(int bookingId) async {
    return await _repository.cancelBooking(bookingId);
  }
}
