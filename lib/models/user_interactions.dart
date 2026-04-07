class Badge {
  final String name;
  final String icon;
  final bool earned;

  Badge({
    required this.name,
    required this.icon,
    required this.earned,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      name: json['name'] as String? ?? 'Badge',
      icon: json['icon'] as String? ?? 'shield',
      earned: json['earned'] as bool? ?? false,
    );
  }
}

class WeeklyStats {
  final int redemptions;
  final int resetTimerSeconds;
  final String resetMessage;

  WeeklyStats({
    required this.redemptions,
    required this.resetTimerSeconds,
    required this.resetMessage,
  });

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      redemptions: json['redemptions'] as int? ?? 0,
      resetTimerSeconds: json['reset_timer_seconds'] as int? ?? 0,
      resetMessage: json['reset_message'] as String? ?? '',
    );
  }
}

class Progression {
  final int currentPoints;
  final String tier;
  final String rank;
  final Map<String, dynamic>? nextTier;

  Progression({
    required this.currentPoints,
    required this.tier,
    required this.rank,
    this.nextTier,
  });

  factory Progression.fromJson(Map<String, dynamic> json) {
    return Progression(
      currentPoints: json['current_points'] as int? ?? 0,
      tier: json['tier'] as String? ?? 'Bronze',
      rank: json['rank'] as String? ?? 'Local Foodie',
      nextTier: json['next_tier'] as Map<String, dynamic>?,
    );
  }
}

/// Stat representation for the user profile
class ProfileStats {
  final int dealsClaimed;
  final double moneySaved;
  final Progression progression;
  final WeeklyStats weekly;
  final List<Badge> badges;
  final int restaurantsVisited;
  final int citiesVisited;
  final int favouriteRestaurants;
  final int reviewsWritten;

  ProfileStats({
    required this.dealsClaimed,
    required this.moneySaved,
    required this.progression,
    required this.weekly,
    required this.badges,
    required this.restaurantsVisited,
    required this.citiesVisited,
    required this.favouriteRestaurants,
    required this.reviewsWritten,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      dealsClaimed: json['deals_claimed'] as int? ?? 0,
      moneySaved: (json['money_saved'] as num?)?.toDouble() ?? 0.0,
      progression: json['progression'] != null 
          ? Progression.fromJson(json['progression'] as Map<String, dynamic>)
          : Progression(currentPoints: 0, tier: 'Bronze', rank: 'Foodie'),
      weekly: json['weekly'] != null 
          ? WeeklyStats.fromJson(json['weekly'] as Map<String, dynamic>)
          : WeeklyStats(redemptions: 0, resetTimerSeconds: 0, resetMessage: ''),
      badges: (json['badges'] as List<dynamic>?)
              ?.map((i) => Badge.fromJson(i as Map<String, dynamic>))
              .toList() ?? [],
      restaurantsVisited: json['restaurants_visited'] as int? ?? 0,
      citiesVisited: json['cities_visited'] as int? ?? 0,
      favouriteRestaurants: json['favourite_restaurants'] as int? ?? 0,
      reviewsWritten: json['reviews_written'] as int? ?? 0,
    );
  }
}

/// Booking status enum
enum BookingStatus { pending, confirmed, cancelled, completed }

/// Restaurant Booking model
class Booking {
  final int id;
  final int restaurantId;
  final String restaurantName;
  final String restaurantSlug;
  final String? restaurantCityName;
  final DateTime bookingDate;

  final int numberOfGuests;
  final BookingStatus status;
  final String specialRequests;
  final String contactName;
  final String contactPhone;
  final bool canCancel;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantSlug,
    this.restaurantCityName,
    required this.bookingDate,

    required this.numberOfGuests,
    required this.status,
    required this.specialRequests,
    required this.contactName,
    required this.contactPhone,
    required this.canCancel,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['booking_id'] as int? ?? json['id'] as int? ?? 0,
      restaurantId: json['restaurant_id'] as int? ?? json['restaurant'] as int? ?? 0,
      restaurantName: json['restaurant_name'] as String? ?? '',
      restaurantSlug: json['restaurant_slug'] as String? ?? '',
      restaurantCityName: json['restaurant_city_name'] as String?,
      bookingDate: DateTime.parse(json['booking_date'] as String),

      numberOfGuests: json['number_of_guests'] as int? ?? 1,
      status: _parseBookingStatus(json['status'] as String? ?? 'pending'),
      specialRequests: json['special_requests'] as String? ?? '',
      contactName: json['contact_name'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      canCancel: json['can_cancel'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static BookingStatus _parseBookingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }
}
