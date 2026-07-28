import 'package:discount_buddy/core/domain/error_mapper.dart';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/nearby/data/location_service.dart';
import 'package:discount_buddy/features/nearby/domain/repositories/location_repository.dart';
import 'package:geolocator/geolocator.dart';

class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl({LocationService? service})
      : _service = service ?? LocationService();

  final LocationService _service;

  @override
  Future<Result<Position>> getCurrentPosition({
    required bool requestPermissionIfDenied,
  }) async {
    try {
      final result = await _service.getCurrentLocation(
        requestPermissionIfDenied: requestPermissionIfDenied,
      );
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not get current position'));
    }
  }

  @override
  Future<Result<({Position position, String cityName})>> getUserLocation({
    required bool requestPermissionIfDenied,
  }) async {
    try {
      final result = await _service.getUserLocation(
        requestPermissionIfDenied: requestPermissionIfDenied,
      );
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not get user location'));
    }
  }

  @override
  Future<Result<String>> getCityName(double latitude, double longitude) async {
    try {
      final result = await _service.getCityName(latitude, longitude);
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not get city name'));
    }
  }

  @override
  Future<Result<LocationPermission>> requestPermissionIfNeeded() async {
    try {
      final result = await _service.requestPermissionIfNeeded();
      return Success(result);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Could not request permission'));
    }
  }
}
