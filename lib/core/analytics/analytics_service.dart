import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'analytics_events.dart';

/// Single entry point for Firebase Analytics.
///
/// Every call is fire-and-forget and never throws, so analytics can never
/// block or break a booking, spin, or redemption.
///
/// Access via `AnalyticsService.instance` (registered in InitialBinding).
class AnalyticsService {
  AnalyticsService();

  static AnalyticsService get instance {
    if (Get.isRegistered<AnalyticsService>()) {
      return Get.find<AnalyticsService>();
    }
    return Get.put<AnalyticsService>(AnalyticsService(), permanent: true);
  }

  FirebaseAnalytics? get _analytics {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAnalytics.instance;
  }

  /// Strips nulls and converts values to the `String | num` types Firebase
  /// accepts. Bools become 'true'/'false'. String values are truncated to
  /// Firebase's 100-char parameter limit.
  Map<String, Object> _clean(Map<String, Object?>? params) {
    final out = <String, Object>{};
    if (params == null) return out;
    params.forEach((key, value) {
      if (value == null) return;
      if (value is num) {
        out[key] = value;
      } else if (value is bool) {
        out[key] = value ? 'true' : 'false';
      } else {
        final s = value.toString();
        out[key] = s.length > 100 ? s.substring(0, 100) : s;
      }
    });
    return out;
  }

  void _run(Future<void> Function(FirebaseAnalytics a) action, String label) {
    final analytics = _analytics;
    if (analytics == null) return;
    action(analytics).catchError((Object e) {
      debugPrint('Analytics [$label] failed: $e');
    });
  }

  // ---------------------------------------------------------------------------
  // Generic
  // ---------------------------------------------------------------------------

  void logEvent(String name, {Map<String, Object?>? parameters}) {
    final params = _clean(parameters);
    _run(
      (a) => a.logEvent(name: name, parameters: params.isEmpty ? null : params),
      name,
    );
  }

  void logScreenView(String screenName, {String? screenClass}) {
    _run(
      (a) => a.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      ),
      'screen_view:$screenName',
    );
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  void logSignUp({required String method}) {
    _run((a) => a.logSignUp(signUpMethod: method), 'sign_up');
  }

  void logLogin({required String method}) {
    _run((a) => a.logLogin(loginMethod: method), 'login');
  }

  /// Internal user id only. Pass null on logout.
  void setUserId(int? userId) {
    _run((a) => a.setUserId(id: userId?.toString()), 'set_user_id');
  }

  /// e.g. `customer`, `merchant`, `admin`.
  void setUserType(String? userType) {
    _run(
      (a) => a.setUserProperty(name: 'user_type', value: userType),
      'user_type',
    );
  }

  // ---------------------------------------------------------------------------
  // Restaurants
  // ---------------------------------------------------------------------------

  void restaurantViewed({
    required String restaurantId,
    required String restaurantName,
  }) {
    logEvent(AnalyticsEvents.restaurantViewed, parameters: {
      AnalyticsParams.restaurantId: restaurantId,
      AnalyticsParams.restaurantName: restaurantName,
    });
  }

  void restaurantFavorited({required String restaurantId}) {
    logEvent(AnalyticsEvents.restaurantFavorited, parameters: {
      AnalyticsParams.restaurantId: restaurantId,
    });
  }

  // ---------------------------------------------------------------------------
  // Deals
  // ---------------------------------------------------------------------------

  void dealViewed({required String restaurantId, int? dealId}) {
    logEvent(AnalyticsEvents.dealViewed, parameters: {
      AnalyticsParams.restaurantId: restaurantId,
      AnalyticsParams.dealId: dealId,
    });
  }

  /// [type] is `deal` or `loyalty_visit`. [source] is `details_button`
  /// (Redeem Offer button on the restaurant page) or `confirm` (inside modal).
  void redeemStarted({
    required String restaurantId,
    int? dealId,
    String type = 'deal',
    String source = 'confirm',
  }) {
    logEvent(AnalyticsEvents.redeemStarted, parameters: {
      AnalyticsParams.restaurantId: restaurantId,
      AnalyticsParams.dealId: dealId,
      AnalyticsParams.type: type,
      AnalyticsParams.source: source,
    });
  }

  void dealRedeemed({
    required String restaurantId,
    int? dealId,
    String type = 'deal',
  }) {
    logEvent(AnalyticsEvents.dealRedeemed, parameters: {
      AnalyticsParams.restaurantId: restaurantId,
      AnalyticsParams.dealId: dealId,
      AnalyticsParams.type: type,
    });
  }

  // ---------------------------------------------------------------------------
  // Booking
  // ---------------------------------------------------------------------------

  void bookingStarted({required String restaurantId, String? source}) {
    logEvent(AnalyticsEvents.bookingStarted, parameters: {
      AnalyticsParams.restaurantId: restaurantId,
      AnalyticsParams.source: source,
    });
  }

  void bookingCreated({
    required String restaurantId,
    int? guests,
    String? source,
  }) {
    logEvent(AnalyticsEvents.bookingCreated, parameters: {
      AnalyticsParams.restaurantId: restaurantId,
      AnalyticsParams.guests: guests,
      AnalyticsParams.source: source,
    });
  }

  void bookingCancelled({required int bookingId, String? restaurantId}) {
    logEvent(AnalyticsEvents.bookingCancelled, parameters: {
      AnalyticsParams.bookingId: bookingId,
      AnalyticsParams.restaurantId: restaurantId,
    });
  }

  // ---------------------------------------------------------------------------
  // Loyalty
  // ---------------------------------------------------------------------------

  void loyaltyCardViewed({String? restaurantId, int? cardCount, String? source}) {
    logEvent(AnalyticsEvents.loyaltyCardViewed, parameters: {
      AnalyticsParams.restaurantId: restaurantId,
      AnalyticsParams.cardCount: cardCount,
      AnalyticsParams.source: source,
    });
  }

  /// Logged from the merchant scanner: the stamp is confirmed there.
  void stampCollected({
    String? restaurantId,
    required bool isLoyaltyOnly,
    required bool rewardJustEarned,
  }) {
    logEvent(AnalyticsEvents.stampCollected, parameters: {
      AnalyticsParams.restaurantId: restaurantId,
      AnalyticsParams.isLoyaltyOnly: isLoyaltyOnly,
      AnalyticsParams.rewardJustEarned: rewardJustEarned,
    });
  }

  /// Logged from the merchant scanner when a loyalty reward is claimed.
  void rewardRedeemed({String? restaurantId}) {
    logEvent(AnalyticsEvents.rewardRedeemed, parameters: {
      AnalyticsParams.restaurantId: restaurantId,
    });
  }

  // ---------------------------------------------------------------------------
  // Search / Notifications
  // ---------------------------------------------------------------------------

  void search({required String term, int? resultCount}) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    final safeTerm = trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;
    _run(
      (a) => a.logSearch(
        searchTerm: safeTerm,
        parameters: resultCount == null
            ? null
            : {AnalyticsParams.resultCount: resultCount},
      ),
      'search',
    );
  }

  /// [source] is `push` (system notification tapped) or `in_app` (list tap).
  void notificationOpen({required String source, String? notificationType}) {
    logEvent(AnalyticsEvents.notificationOpen, parameters: {
      AnalyticsParams.source: source,
      AnalyticsParams.notificationType: notificationType,
    });
  }

  // ---------------------------------------------------------------------------
  // Spin to Win
  // ---------------------------------------------------------------------------

  void spinStarted({required int campaignId}) {
    logEvent(AnalyticsEvents.spinStarted, parameters: {
      AnalyticsParams.campaignId: campaignId,
    });
  }

  void spinCompleted({
    required int campaignId,
    required bool isWin,
    String? prizeTitle,
  }) {
    logEvent(AnalyticsEvents.spinCompleted, parameters: {
      AnalyticsParams.campaignId: campaignId,
      AnalyticsParams.isWin: isWin,
      AnalyticsParams.prizeTitle: prizeTitle,
    });
  }
}
