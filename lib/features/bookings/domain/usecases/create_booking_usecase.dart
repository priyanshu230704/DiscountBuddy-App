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
  }) {
    return _repository.createBooking(
      restaurantId: restaurantId,
      bookingDate: bookingDate,
      numberOfGuests: numberOfGuests,
      specialRequests: specialRequests,
      contactName: contactName,
      contactPhone: contactPhone,
    );
  }
}
