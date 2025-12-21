import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service for location-related operations
class LocationService {
  /// Get current location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
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
        
        // Try to get city, then locality, then subAdministrativeArea, then administrativeArea
        String? cityName = placemark.locality ?? 
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
      final cityName = await getCityName(
        position.latitude,
        position.longitude,
      );
      
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
}

