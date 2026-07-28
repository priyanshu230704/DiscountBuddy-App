import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class UpdateOccupancyUseCase {
  UpdateOccupancyUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call(int restaurantId, String occupancy) =>
      _repository.updateOccupancy(restaurantId, occupancy);
}
