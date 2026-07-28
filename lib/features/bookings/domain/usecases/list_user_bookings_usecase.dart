import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/bookings/domain/repositories/booking_repository.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';

class ListUserBookingsUseCase {
  ListUserBookingsUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<List<Booking>>> call({String? status}) {
    return _repository.listUserBookings(status: status);
  }
}
