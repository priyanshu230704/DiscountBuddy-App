import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service for location-related operations
class LocationService {
  /// Get current location — checks permission and requests if needed.
  /// Throws [LocationServiceDisabledException] if GPS/location is turned off and no last known position.
  /// Throws [LocationPermissionDeniedException] if user denied permission.
  Future<Position> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException();
    }

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

        // Try to get subLocality, then locality, then subAdministrativeArea, then administrativeArea
        String? cityName =
            placemark.subLocality ??
            placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea;

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
        if (placemark.administrativeArea != null) {
          return placemark.administrativeArea!;
        }
        if (placemark.country != null) {
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
  Future<({Position position, String cityName})> getUserLocation() async {
    final position = await getCurrentLocation();
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
  @override
  String toString() =>
      'Location permissions are denied. Please grant location access.';
}
