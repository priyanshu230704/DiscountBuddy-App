import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/nearby/domain/repositories/location_repository.dart';

class GetUserLocationUseCase {
  GetUserLocationUseCase(this._repository);

  final LocationRepository _repository;

  Future<Result<({
    @Deprecated('Use position instead') dynamic position,
    String cityName,
  })>> call({bool requestPermissionIfDenied = false}) async {
    return _repository.getUserLocation(
      requestPermissionIfDenied: requestPermissionIfDenied,
    );
  }
}
