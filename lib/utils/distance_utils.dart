import 'package:geolocator/geolocator.dart';

/// Utility class for pinpoint-accurate distance calculations.
/// Always uses the Geolocator Haversine formula (same as GPS devices).
class DistanceUtils {
  DistanceUtils._();

  /// Meters per mile (exact)
  static const double _metersPerMile = 1609.344;

  /// Convert meters to miles.
  static double metersToMiles(double meters) => meters / _metersPerMile;

  /// Convert kilometres to miles.
  static double kmToMiles(double km) => km * 1000 / _metersPerMile;

  /// Compute the straight-line distance in miles between the user's position
  /// and a restaurant's position using the Haversine formula via Geolocator.
  ///
  /// Returns `null` if any coordinate is missing or zero/invalid.
  static double? computeMiles({
    required double? userLat,
    required double? userLon,
    required double restaurantLat,
    required double restaurantLon,
  }) {
    if (userLat == null || userLon == null) return null;
    if (restaurantLat == 0.0 && restaurantLon == 0.0) return null;

    final meters = Geolocator.distanceBetween(
      userLat,
      userLon,
      restaurantLat,
      restaurantLon,
    );
    return metersToMiles(meters);
  }

  /// Returns the best available miles value for display, in priority order:
  /// 1. Haversine-computed from user GPS (most accurate)
  /// 2. `distanceMiles` from API (already in miles)
  /// 3. `distanceKm` converted to miles (fallback)
  /// 4. `null` if nothing is available
  static double? bestMiles({
    double? userLat,
    double? userLon,
    required double restaurantLat,
    required double restaurantLon,
    double? distanceMilesFromApi,
    double distanceKmFromApi = 0.0,
  }) {
    // Priority 1: compute from real GPS
    final computed = computeMiles(
      userLat: userLat,
      userLon: userLon,
      restaurantLat: restaurantLat,
      restaurantLon: restaurantLon,
    );
    if (computed != null) return computed;

    // Priority 2: use the value the server already computed in miles
    if (distanceMilesFromApi != null && distanceMilesFromApi > 0) {
      return distanceMilesFromApi;
    }

    // Priority 3: convert the km value the server returned
    if (distanceKmFromApi > 0) return kmToMiles(distanceKmFromApi);

    return null;
  }

  /// Format miles for display, e.g. "1.2 miles"
  static String formatMiles(double? miles, {int decimals = 1}) {
    if (miles == null || miles < 0) return '— miles';
    return '${miles.toStringAsFixed(decimals)} miles';
  }
}
