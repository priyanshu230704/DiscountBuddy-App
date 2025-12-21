/// Environment configuration for the DiscountBuddy app
class Environment {
  // Environment mode
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  // Current environment - change this based on your build configuration
  static const String currentEnvironment = development;

  // API Base URLs
  static String get baseUrl {
    switch (currentEnvironment) {
      case production:
        return 'https://api.discountbuddy.com';
      case staging:
        return 'https://staging-api.discountbuddy.com';
      case development:
      default:
        return 'http://10.174.83.186:8000';
    }
  }

  // API Timeout
  static const Duration apiTimeout = Duration(seconds: 30);

  // API Version
  static const String apiVersion = 'v1';

  // Get full API URL
  static String get apiUrl => '$baseUrl/api';

  // App Configuration
  static const String appName = 'DiscountBuddy';
  static const String appVersion = '1.0.0';

  // Feature Flags
  static bool get enableLogging => currentEnvironment != production;
  static bool get enableDebugMode => currentEnvironment == production;
}

