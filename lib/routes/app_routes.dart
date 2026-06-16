class AppRoutes {
  AppRoutes._();

  // Startup & Auth
  static const String splash = '/';
  static const String onboardingCheck = '/onboarding-check';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String appUpdate = '/app-update';

  // User Pages - Profile & Settings
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String levelProgress = '/level-progress';
  static const String savingsHistory = '/savings-history';
  static const String savedRestaurants = '/saved-restaurants';
  static const String joinPartner = '/join-partner';
  static const String helpSupport = '/help-support';
  static const String privacyPolicy = '/privacy-policy';

  // User Pages - Browse & Search
  static const String search = '/search';
  static const String restaurantDetails = '/restaurant-details';
  static const String myDeals = '/my-deals';
  static const String notifications = '/notifications';

  // User Bookings
  static const String bookings = '/bookings';
  static const String createBooking = '/create-booking';

  // Merchant Pages - Main Tabs
  static const String merchantDashboard = '/merchant-dashboard';
  static const String merchantRestaurants = '/merchant-restaurants';
  static const String merchantMenu = '/merchant-menu';

  // Merchant Pages - Sub-pages
  static const String addRestaurant = '/add-restaurant';
  static const String merchantDeals = '/merchant-deals';
  static const String addDeal = '/add-deal';
  static const String merchantBookings = '/merchant-bookings';
  static const String merchantReviews = '/merchant-reviews';
  static const String merchantAnalytics = '/merchant-analytics';
  static const String merchantRedemptionHistory = '/merchant-redemption-history';
  static const String qrScanner = '/qr-scanner';
}
