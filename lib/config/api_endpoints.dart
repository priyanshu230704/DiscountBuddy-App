class ApiEndpoints {
  // Auth Routes
  static const String register = '/users/register/';
  static const String login = '/users/token/';
  static const String refreshToken = '/users/token/refresh/';
  static const String googleLogin = '/users/google';
  static const String currentUser = '/users/me/';

  // Restaurant Routes
  static const String restaurants = '/restaurants/restaurants';
  static const String profileStats = '/restaurants/profile/stats/';
  static const String bookings = '/restaurants/bookings/';
  static const String reviews = '/restaurants/reviews/';
  static const String savedRestaurants = '/restaurants/restaurants/saved';
  static const String nearbyRestaurants = '/restaurants/nearby';
  static const String searchRestaurants = '/restaurants/search';
  static const String homeData = '/restaurants/home/';

  // Dynamic Routes
  static String bookingDetail(int bookingId) =>
      '/restaurants/bookings/$bookingId/';
  static String cancelBooking(int bookingId) =>
      '/restaurants/bookings/$bookingId/cancel/';

  static String toggleFavourite(String slug) =>
      '/restaurants/restaurant-detail/$slug/favourite/';

  static String claimDeal(int dealId) => '/restaurants/deals/$dealId/use/';

  static String restaurantById(String id) => '/restaurants/$id';

  static String restaurantDetail(String slug) {
    // Logic from the original service to clean the slug
    final cleanSlug = slug.trim().replaceAll(RegExp(r'/+$'), '');
    return '/restaurants/restaurant-detail/$cleanSlug';
  }

  // Merchant Routes
  static const String merchantRestaurants = '/restaurants/restaurant/manage/';
  static String merchantRestaurantDetail(int id) =>
      '/restaurants/restaurant/manage/$id/';

  static const String merchantDeals = '/restaurants/deals/';
  static String merchantDealDetail(int id) => '/restaurants/deals/$id/';

  static const String merchantMenu = '/restaurants/restaurant/menu/';
  static String merchantMenuDetail(int id) =>
      '/restaurants/restaurant/menu/$id/';

  static const String merchantOpeningSlots =
      '/restaurants/restaurant/opening-slots/';

  static const String merchantReviews = '/restaurants/restaurant/reviews/';
  static const String merchantBookings = '/restaurants/restaurant/bookings/';

  // Common/Reference Routes
  static const String cities = '/restaurants/cities/';
  static const String categories = '/restaurants/categories/';

  // Wallet & Vouchers
  static const String userVouchers = '/vouchers/me/';
  static const String wallet = '/wallet/';
}
