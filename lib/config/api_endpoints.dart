class ApiEndpoints {
  // Auth Routes
  static const String register = '/users/register';
  static const String registerInit = '/users/register/init';
  static const String verifyOtp = '/users/register/verify-otp';
  static const String registerComplete = '/users/register/complete';
  static const String login = '/users/token';
  static const String refreshToken = '/users/token/refresh';
  // Unified social login endpoint
  static const String oauthLogin = '/users/oauth';
  static const String currentUser = '/users/me';
  static const String passwordReset = '/users/password-reset';
  static const String deleteAccount = '/users/account-delete';
  static const String deleteAccountInit = '/users/account-delete/init';

  // Restaurant Routes
  static const String restaurants = '/restaurants/restaurants';
  static const String profileStats = '/restaurants/profile/stats';
  static const String bookings = '/restaurants/bookings';
  static const String reviews = '/restaurants/reviews';
  static const String savedRestaurants = '/restaurants/restaurants/saved';
  static const String nearbyRestaurants = '/restaurants/restaurants/nearby';
  static const String searchRestaurantsByBounds =
      '/restaurants/restaurants/nearby';
  static const String searchRestaurants = '/restaurants/search';
  static const String homeData = '/restaurants/home';
  static const String dealUses = '/restaurants/deal-uses';
  static const String mysteryVisits = '/restaurants/mystery-visits';

  // Dynamic Routes
  static String bookingDetail(int bookingId) =>
      '/restaurants/bookings/$bookingId';
  static String cancelBooking(int bookingId) =>
      '/restaurants/bookings/$bookingId/cancel';

  static String toggleFavourite(String slug) =>
      '/restaurants/restaurant-detail/$slug/favourite';

  static String claimDeal(int dealId) => '/restaurants/deals/$dealId/use';

  static String mysteryVisitDetail(int id) => '/restaurants/mystery-visits/$id';
  static String startMysteryVisit(int id) =>
      '/restaurants/mystery-visits/$id/start';
  static String submitMysteryVisit(int id) =>
      '/restaurants/mystery-visits/$id/submit';
  static String uploadMysteryEvidence(int id) =>
      '/restaurants/mystery-visits/$id/evidence';

  static String restaurantById(String id) => '/restaurants/$id';

  static String restaurantDetail(String slug) {
    // Logic from the original service to clean the slug
    final cleanSlug = slug.trim().replaceAll(RegExp(r'/+$'), '');
    return '/restaurants/restaurant-detail/$cleanSlug';
  }

  // Merchant Routes
  static const String merchantRestaurants = '/restaurants/restaurant/manage';
  static String merchantRestaurantDetail(int id) =>
      '/restaurants/restaurant/manage/$id';
  static const String merchantUpdateOccupancy = '/restaurants/restaurant/occupancy';
  static const String merchantDashboard = '/restaurants/dashboard';

  static const String merchantDeals = '/restaurants/deals';
  static String merchantDealDetail(int id) => '/restaurants/deals/$id';
  static String toggleDealStatus(int id) => '/restaurants/deals/$id/toggle_status';

  static const String merchantMenu = '/restaurants/restaurant/menu';
  static String merchantMenuDetail(int id) =>
      '/restaurants/restaurant/menu/$id';

  static const String merchantMenuItems = '/restaurants/restaurant/menu-items';
  static String merchantMenuItemDetail(int id) =>
      '/restaurants/restaurant/menu-items/$id';

  static const String merchantOpeningSlots =
      '/restaurants/restaurant/opening-slots';

  static const String merchantReviews = '/restaurants/restaurant/reviews';
  static const String merchantBookings = '/restaurants/restaurant/bookings';
  static String merchantBookingDetail(int id) =>
      '/restaurants/restaurant/bookings/$id';
  static const String merchantRedeemDeal = '/restaurants/deals/redeem';
  static const String merchantRedemptionHistory = '/restaurants/deals/redemption-history';

  static const String merchantRestaurantImages = '/restaurants/restaurant-images';
  static String merchantRestaurantImageDetail(int id) =>
      '/restaurants/restaurant-images/$id';

  // Common/Reference Routes
  static const String cities = '/restaurants/cities';
  static const String categories = '/restaurants/categories';
  static const String facilityList = '/restaurants/facilities';

  // Wallet & Vouchers
  static const String userVouchers = '/vouchers/me';
  static const String wallet = '/wallet';

  // Notifications
  static const String registerDeviceToken = '/notifications/devices';
  static const String deviceTokens = '/notifications/devices';

  static String deactivateDeviceToken(String tokenId) =>
      '/notifications/devices/$tokenId/deactivate';

  static String deleteDeviceToken(String tokenId) =>
      '/notifications/devices/$tokenId';

  static const String notifications = '/notifications';
  static const String unreadNotificationCount = '/notifications/unread_count';
  static const String markAllNotificationsRead = '/notifications/read_all';

  static String notificationDetail(String notificationId) =>
      '/notifications/$notificationId';

  static String markNotificationRead(String notificationId) =>
      '/notifications/$notificationId/mark_read';
}
