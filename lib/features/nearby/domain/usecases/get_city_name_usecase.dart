import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/nearby/domain/repositories/location_repository.dart';

class GetCityNameUseCase {
  GetCityNameUseCase(this._repository);

  final LocationRepository _repository;

  Future<Result<String>> call(double latitude, double longitude) async {
    return _repository.getCityName(latitude, longitude);
  }
}
