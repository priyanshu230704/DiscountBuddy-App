import 'package:flutter/material.dart';
import 'package:discount_buddy/features/nearby/data/location_repository_impl.dart';
import 'package:discount_buddy/features/nearby/domain/repositories/location_repository.dart';
import 'package:discount_buddy/features/nearby/domain/usecases/get_current_position_usecase.dart';
import 'package:discount_buddy/features/nearby/domain/usecases/get_user_location_usecase.dart';
import 'package:discount_buddy/features/nearby/domain/usecases/get_city_name_usecase.dart';
import 'package:geolocator/geolocator.dart';

class NearbyProvider extends ChangeNotifier {
  final LocationRepository _repository;
  late final GetCurrentPositionUseCase _getCurrentPositionUseCase;
  late final GetUserLocationUseCase _getUserLocationUseCase;
  late final GetCityNameUseCase _getCityNameUseCase;

  NearbyProvider({LocationRepository? repository})
      : _repository = repository ?? LocationRepositoryImpl() {
    _getCurrentPositionUseCase = GetCurrentPositionUseCase(_repository);
    _getUserLocationUseCase = GetUserLocationUseCase(_repository);
    _getCityNameUseCase = GetCityNameUseCase(_repository);
  }

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<Position?> getCurrentPosition({bool requestPermissionIfDenied = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _getCurrentPositionUseCase(
      requestPermissionIfDenied: requestPermissionIfDenied,
    );

    _isLoading = false;
    return result.fold(
      onSuccess: (position) {
        notifyListeners();
        return position;
      },
      onError: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return null;
      },
    );
  }

  Future<({Position position, String cityName})?> getUserLocation({
    bool requestPermissionIfDenied = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _getUserLocationUseCase(
      requestPermissionIfDenied: requestPermissionIfDenied,
    );

    _isLoading = false;
    if (result.isSuccess) {
      notifyListeners();
      final location = result.valueOrNull!;
      return (position: location.position as Position, cityName: location.cityName);
    } else {
      _errorMessage = result.failureOrNull?.message;
      notifyListeners();
      return null;
    }
  }

  Future<String?> getCityName(double latitude, double longitude) async {
    final result = await _getCityNameUseCase(latitude, longitude);

    return result.fold(
      onSuccess: (cityName) => cityName,
      onError: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return null;
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
