import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/bookings/domain/repositories/booking_repository.dart';

class DeleteBookingUseCase {
  DeleteBookingUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<void>> call(int bookingId) {
    return _repository.deleteBooking(bookingId);
  }
}
