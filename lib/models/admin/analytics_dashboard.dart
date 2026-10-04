class AdminAnalyticsDashboard {
  final AdminAnalyticsRange range;
  final AdminAnalyticsOverview overview;
  final int realtimeActiveUsers;
  final List<AdminAnalyticsPlatform> platforms;
  final List<AdminAnalyticsVersion> appVersions;
  final List<AdminAnalyticsDailyUsers> dailyUsers;
  final List<AdminAnalyticsEngagement> engagement;
  final AdminAnalyticsBehaviour behaviour;
  final AdminAnalyticsBusiness business;

  AdminAnalyticsDashboard({
    required this.range,
    required this.overview,
    required this.realtimeActiveUsers,
    required this.platforms,
    required this.appVersions,
    required this.dailyUsers,
    required this.engagement,
    required this.behaviour,
    required this.business,
  });

  factory AdminAnalyticsDashboard.fromJson(Map<String, dynamic> json) {
    final realtime = json['realtime'];
    return AdminAnalyticsDashboard(
      range: AdminAnalyticsRange.fromJson(json['range'] as Map<String, dynamic>? ?? {}),
      overview: AdminAnalyticsOverview.fromJson(json['overview'] as Map<String, dynamic>? ?? {}),
      realtimeActiveUsers: realtime is Map<String, dynamic>
          ? (realtime['active_users'] as num?)?.toInt() ?? 0
          : 0,
      platforms: _list(json['platforms']).map(AdminAnalyticsPlatform.fromJson).toList(),
      appVersions: _list(json['app_versions']).map(AdminAnalyticsVersion.fromJson).toList(),
      dailyUsers: _list(json['daily_users']).map(AdminAnalyticsDailyUsers.fromJson).toList(),
      engagement: _list(json['engagement']).map(AdminAnalyticsEngagement.fromJson).toList(),
      behaviour: AdminAnalyticsBehaviour.fromJson(json['behaviour'] as Map<String, dynamic>? ?? {}),
      business: AdminAnalyticsBusiness.fromJson(json['business'] as Map<String, dynamic>? ?? {}),
    );
  }

  static List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}

class AdminAnalyticsRange {
  final String startDate;
  final String endDate;

  AdminAnalyticsRange({required this.startDate, required this.endDate});

  factory AdminAnalyticsRange.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsRange(
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
    );
  }
}

class AdminAnalyticsOverview {
  final int activeUsers;
  final int newUsers;
  final int sessions;
  final int eventCount;
  final int screenViews;

  AdminAnalyticsOverview({
    required this.activeUsers,
    required this.newUsers,
    required this.sessions,
    required this.eventCount,
    required this.screenViews,
  });

  factory AdminAnalyticsOverview.fromJson(Map<String, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return AdminAnalyticsOverview(
      activeUsers: n('active_users'),
      newUsers: n('new_users'),
      sessions: n('sessions'),
      eventCount: n('event_count'),
      screenViews: n('screen_views'),
    );
  }
}

class AdminAnalyticsPlatform {
  final String platform;
  final int activeUsers;

  AdminAnalyticsPlatform({required this.platform, required this.activeUsers});

  factory AdminAnalyticsPlatform.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsPlatform(
      platform: json['platform'] as String? ?? '',
      activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminAnalyticsVersion {
  final String version;
  final int activeUsers;

  AdminAnalyticsVersion({required this.version, required this.activeUsers});

  factory AdminAnalyticsVersion.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsVersion(
      version: json['version'] as String? ?? '',
      activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminAnalyticsEngagement {
  final String eventName;
  final String label;
  final int count;
  final List<AdminAnalyticsNamedCount> details;

  AdminAnalyticsEngagement({
    required this.eventName,
    required this.label,
    required this.count,
    required this.details,
  });

  factory AdminAnalyticsEngagement.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsEngagement(
      eventName: json['event_name'] as String? ?? '',
      label: json['label'] as String? ?? json['event_name'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      details: AdminAnalyticsDashboard._list(json['details'])
          .map(AdminAnalyticsNamedCount.fromJson)
          .toList(),
    );
  }
}

class AdminAnalyticsNamedCount {
  final String name;
  final int count;

  AdminAnalyticsNamedCount({required this.name, required this.count});

  factory AdminAnalyticsNamedCount.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsNamedCount(
      name: json['name'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? (json['views'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminAnalyticsDailyUsers {
  final String date;
  final int activeUsers;
  final int newUsers;

  AdminAnalyticsDailyUsers({
    required this.date,
    required this.activeUsers,
    required this.newUsers,
  });

  factory AdminAnalyticsDailyUsers.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsDailyUsers(
      date: json['date'] as String? ?? '',
      activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
      newUsers: (json['new_users'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminAnalyticsBehaviour {
  final int restaurantViews;
  final int dealViews;
  final int redeemStarted;
  final int bookingStarted;
  final int firstOpens;
  final int androidAppRemoves;

  AdminAnalyticsBehaviour({
    required this.restaurantViews,
    required this.dealViews,
    required this.redeemStarted,
    required this.bookingStarted,
    required this.firstOpens,
    required this.androidAppRemoves,
  });

  factory AdminAnalyticsBehaviour.fromJson(Map<String, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return AdminAnalyticsBehaviour(
      restaurantViews: n('restaurant_views'),
      dealViews: n('deal_views'),
      redeemStarted: n('redeem_started'),
      bookingStarted: n('booking_started'),
      firstOpens: n('first_opens'),
      androidAppRemoves: n('android_app_removes'),
    );
  }
}

class AdminAnalyticsBusiness {
  final int bookingsCreated;
  final int bookingsConfirmed;
  final int bookingsCancelled;
  final int noShows;
  final int redemptions;
  final double redemptionValue;
  final int restaurantDetailViews;
  final int dealViews;
  final List<AdminAnalyticsTopRestaurant> topRestaurants;

  AdminAnalyticsBusiness({
    required this.bookingsCreated,
    required this.bookingsConfirmed,
    required this.bookingsCancelled,
    required this.noShows,
    required this.redemptions,
    required this.redemptionValue,
    required this.restaurantDetailViews,
    required this.dealViews,
    required this.topRestaurants,
  });

  factory AdminAnalyticsBusiness.fromJson(Map<String, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    final rawTop = json['top_restaurants'];
    return AdminAnalyticsBusiness(
      bookingsCreated: n('bookings_created'),
      bookingsConfirmed: n('bookings_confirmed'),
      bookingsCancelled: n('bookings_cancelled'),
      noShows: n('no_shows'),
      redemptions: n('redemptions'),
      redemptionValue: (json['redemption_value'] as num?)?.toDouble() ?? 0,
      restaurantDetailViews: n('restaurant_detail_views'),
      dealViews: n('deal_views'),
      topRestaurants: rawTop is List
          ? rawTop.whereType<Map<String, dynamic>>().map(AdminAnalyticsTopRestaurant.fromJson).toList()
          : const [],
    );
  }
}

class AdminAnalyticsTopRestaurant {
  final int restaurantId;
  final String name;
  final int views;

  AdminAnalyticsTopRestaurant({
    required this.restaurantId,
    required this.name,
    required this.views,
  });

  factory AdminAnalyticsTopRestaurant.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsTopRestaurant(
      restaurantId: (json['restaurant_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      views: (json['views'] as num?)?.toInt() ?? 0,
    );
  }
}
