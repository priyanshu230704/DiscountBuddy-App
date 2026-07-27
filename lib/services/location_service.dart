import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service for location-related operations
class LocationService {
  /// Current permission status without prompting the user.
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  static bool isPermissionGranted(LocationPermission permission) =>
      permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;

  /// Whether the OS has not been asked yet, or the user denied without blocking.
  static bool canRequestPermission(LocationPermission permission) =>
      permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine;

  /// Show the system location permission dialog when still undecided.
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  /// Request location permission if the user has not been asked yet.
  /// Safe to call after other startup dialogs (e.g. notifications on iOS).
  Future<LocationPermission> requestPermissionIfNeeded() async {
    final current = await checkPermission();
    if (!canRequestPermission(current)) return current;
    return requestPermission();
  }

  Future<LocationPermission> _ensurePermission({
    required bool requestPermissionIfDenied,
  }) async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException(isPermanent: true);
    }

    if (requestPermissionIfDenied && canRequestPermission(permission)) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException(isPermanent: true);
    }

    if (!isPermissionGranted(permission)) {
      throw LocationPermissionDeniedException(isPermanent: false);
    }

    return permission;
  }

  /// Get current location.
  ///
  /// Set [requestPermissionIfDenied] to `true` only on first explicit prompt
  /// (e.g. home screen init). When `false`, denied permission throws immediately
  /// without re-showing the system dialog.
  Future<Position> getCurrentLocation({
    bool requestPermissionIfDenied = false,
  }) async {
    await _ensurePermission(requestPermissionIfDenied: requestPermissionIfDenied);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    // Always try to get last known position first for speed
    final lastKnown = await Geolocator.getLastKnownPosition();

    if (!serviceEnabled && lastKnown == null) {
      throw LocationServiceDisabledException();
    }

    // If we have a fairly recent last known position, return it immediately
    if (lastKnown != null) {
      // Background update the fresh position without waiting
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).catchError((_) => lastKnown); // Fail silently

      return lastKnown;
    }

    // Otherwise, wait for a fresh fix but use medium accuracy (much faster than high)
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  }

  /// Get city name from coordinates using reverse geocoding
  Future<String> getCityName(double latitude, double longitude) async {
    try {
      // Use reverse geocoding to get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        // Helper to treat empty strings as null
        String? validString(String? val) =>
            (val != null && val.isNotEmpty) ? val : null;

        String? cityName =
            validString(placemark.subLocality) ??
            validString(placemark.locality) ??
            validString(placemark.subAdministrativeArea) ??
            validString(placemark.administrativeArea);

        // If still no city, try to get country
        if (cityName == null || cityName.isEmpty) {
          cityName = placemark.country;
        }

        // If we have a city name, return it
        if (cityName != null && cityName.isNotEmpty) {
          return cityName;
        }
      }

      // Fallback: return formatted location string
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          return placemark.administrativeArea!;
        }
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          return placemark.country!;
        }
      }

      return 'Unknown Location';
    } catch (e) {
      // If reverse geocoding fails, return a generic message
      return 'Location Unavailable';
    }
  }

  /// Get user's city with fallback options
  Future<String> getUserCity() async {
    try {
      final position = await getCurrentLocation();
      final cityName = await getCityName(position.latitude, position.longitude);

      // If we got a valid city name, return it
      if (cityName.isNotEmpty &&
          cityName != 'Unknown Location' &&
          cityName != 'Location Unavailable') {
        return cityName;
      }

      // Fallback to country or default
      return 'Your Location';
    } catch (e) {
      // If everything fails, return a user-friendly message
      return 'Your Location';
    }
  }

  /// Get user's full location data (position + city name) in one call.
  /// Returns a record with position and city name.
  /// Throws if location cannot be obtained.
  Future<({Position position, String cityName})> getUserLocation({
    bool requestPermissionIfDenied = false,
  }) async {
    final position = await getCurrentLocation(
      requestPermissionIfDenied: requestPermissionIfDenied,
    );
    final cityName = await getCityName(position.latitude, position.longitude);

    final validCity =
        (cityName.isNotEmpty &&
            cityName != 'Unknown Location' &&
            cityName != 'Location Unavailable')
        ? cityName
        : 'Your Location';

    return (position: position, cityName: validCity);
  }
}

/// Custom exception for location services being disabled
class LocationServiceDisabledException implements Exception {
  @override
  String toString() =>
      'Location services are disabled. Please enable them in Settings.';
}

/// Custom exception for location permissions being denied
class LocationPermissionDeniedException implements Exception {
  final bool isPermanent;

  LocationPermissionDeniedException({this.isPermanent = false});

  @override
  String toString() => isPermanent
      ? 'Location permissions are permanently denied. Enable them in Settings.'
      : 'Location permissions are denied. Please grant location access.';
}
