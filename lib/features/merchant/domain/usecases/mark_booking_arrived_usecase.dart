import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class MarkBookingArrivedUseCase {
  MarkBookingArrivedUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call(int bookingId, String arrivalTime) =>
      _repository.markBookingArrived(bookingId, arrivalTime);
}
