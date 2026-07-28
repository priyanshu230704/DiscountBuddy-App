import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/nearby/domain/repositories/location_repository.dart';
import 'package:geolocator/geolocator.dart';

class GetCurrentPositionUseCase {
  GetCurrentPositionUseCase(this._repository);

  final LocationRepository _repository;

  Future<Result<Position>> call({bool requestPermissionIfDenied = false}) async {
    return _repository.getCurrentPosition(
      requestPermissionIfDenied: requestPermissionIfDenied,
    );
  }
}
