/// Firebase Analytics event and parameter names.
///
/// Automatic events (do NOT log manually): first_open, session_start,
/// user_engagement, app_update, app_remove (Android only).
class AnalyticsEvents {
  AnalyticsEvents._();

  // Restaurants
  static const restaurantViewed = 'restaurant_viewed';
  static const restaurantFavorited = 'restaurant_favorited';

  // Deals
  static const dealViewed = 'deal_viewed';
  static const redeemStarted = 'redeem_started';
  static const dealRedeemed = 'deal_redeemed';

  // Booking
  static const bookingStarted = 'booking_started';
  static const bookingCreated = 'booking_created';
  static const bookingCancelled = 'booking_cancelled';

  // Loyalty
  static const loyaltyCardViewed = 'loyalty_card_viewed';
  static const stampCollected = 'stamp_collected';
  static const rewardRedeemed = 'reward_redeemed';

  // Engagement
  static const notificationOpen = 'notification_open';

  // Spin to Win
  static const spinStarted = 'spin_started';
  static const spinCompleted = 'spin_completed';
}

/// Screen names passed to `logScreenView`.
class AnalyticsScreens {
  AnalyticsScreens._();

  static const home = 'Home';
  static const search = 'Search';
  static const nearby = 'Nearby';
  static const bookings = 'Bookings';
  static const notifications = 'Notifications';
  static const profile = 'Profile';
  static const restaurantDetails = 'RestaurantDetails';
  static const loyaltyWallet = 'LoyaltyWallet';
  static const spinToWin = 'SpinToWin';
}

/// Parameter keys. Internal ids only, never PII.
class AnalyticsParams {
  AnalyticsParams._();

  static const restaurantId = 'restaurant_id';
  static const restaurantName = 'restaurant_name';
  static const dealId = 'deal_id';
  static const bookingId = 'booking_id';
  static const guests = 'guests';
  static const type = 'type';
  static const source = 'source';
  static const notificationType = 'notification_type';
  static const campaignId = 'campaign_id';
  static const isWin = 'is_win';
  static const prizeTitle = 'prize_title';
  static const cardCount = 'card_count';
  static const resultCount = 'result_count';
  static const isLoyaltyOnly = 'is_loyalty_only';
  static const rewardJustEarned = 'reward_just_earned';
}
