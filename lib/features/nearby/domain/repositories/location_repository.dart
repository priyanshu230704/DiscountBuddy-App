import 'package:discount_buddy/core/domain/result.dart';
import 'package:geolocator/geolocator.dart';

/// Intent-based location contract.
abstract class LocationRepository {
  Future<Result<Position>> getCurrentPosition({
    required bool requestPermissionIfDenied,
  });

  Future<Result<({Position position, String cityName})>> getUserLocation({
    required bool requestPermissionIfDenied,
  });

  Future<Result<String>> getCityName(double latitude, double longitude);

  Future<Result<LocationPermission>> requestPermissionIfNeeded();
}
