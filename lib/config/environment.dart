import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for the DiscountBuddy app
class Environment {
  // Environment mode
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  // Current environment - change this based on your build configuration
  static const String currentEnvironment = production;

  // API Base URLs
  static String get baseUrl {
    switch (currentEnvironment) {
      case production:
        return 'http://10.82.45.186:8000';
      case staging:
        return 'http://192.168.29.221:8000';
      case development:
      default:
        return 'http://192.168.29.221:8000';
    }
  }

  // API Timeout
  static const Duration apiTimeout = Duration(seconds: 30);

  // API Version
  static const String apiVersion = 'v1';

  // Get full API URL
  static String get apiUrl => '$baseUrl/api';

  // Specific API URLs based on documentation
  static String get userApiUrl => '$baseUrl/user/api';
  static String get merchantApiUrl => '$baseUrl/merchant/api';

  // App Configuration
  static const String appName = 'DiscountBuddy';
  static const String appVersion = '1.0.0';

  // Feature Flags
  static bool get enableLogging => currentEnvironment != production;
  static bool get enableDebugMode => false; // currentEnvironment == production;

  // Mapbox Configuration
  static String get mapboxAccessToken => dotenv.env['MAPBOX_TOKEN'] ?? '';
}
