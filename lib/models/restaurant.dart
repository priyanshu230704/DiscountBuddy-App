/// Opening Slot model
class OpeningSlot {
  final String dayName;
  final String openingTime;
  final String closingTime;
  final bool isClosed;

  OpeningSlot({
    required this.dayName,
    required this.openingTime,
    required this.closingTime,
    required this.isClosed,
  });

  factory OpeningSlot.fromJson(Map<String, dynamic> json) {
    return OpeningSlot(
      dayName: json['day_name'] as String? ?? '',
      openingTime: json['opening_time'] as String? ?? '',
      closingTime: json['closing_time'] as String? ?? '',
      isClosed: json['is_closed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_name': dayName,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'is_closed': isClosed,
    };
  }
}

/// Helper to safely parse a value to double
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Helper to safely parse a value to int
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Restaurant model
class Restaurant {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String address;
  final double latitude;
  final double longitude;
  final String cuisine;
  final String? occupancy; // available, busy, full
  final double rating;
  final int reviewCount;
  final double distance; // in km
  final double? distanceMiles; // directly from API
  final Discount discount;
  final List<String> images;
  final String phoneNumber;
  final String website;
  final List<String> openingHours;
  final bool requiresBooking;
  final List<String> restrictions;
  final double leaderboardScore; // 0-100 score
  final String? slug; // Optional slug for API calls
  final int? priceRange; // Price range 1-4
  final String? postcode;
  final String? email;
  final bool isFavourite;
  final List<OpeningSlot> openingSlots;
  final List<Discount> activeDeals;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.cuisine,
    this.occupancy,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    this.distanceMiles,
    required this.discount,
    this.images = const [],
    this.phoneNumber = '',
    this.website = '',
    this.openingHours = const [],
    this.requiresBooking = false,
    this.restrictions = const [],
    this.slug,
    this.priceRange,
    this.postcode,
    this.email,
    this.isFavourite = false,
    this.openingSlots = const [],
    this.activeDeals = const [],
    this.leaderboardScore = 0.0,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
      cuisine: json['cuisine'] as String? ?? '',
      occupancy: json['occupancy'] as String?,
      rating: _parseDouble(json['rating']) ?? 0.0,
      reviewCount: _parseInt(json['reviewCount']) ?? 0,
      distance: _parseDouble(json['distance']) ?? 0.0,
      distanceMiles: _parseDouble(json['distance_miles']),
      discount: json['discount'] != null
          ? Discount.fromJson(json['discount'] as Map<String, dynamic>)
          : Discount(type: 'none', description: ''),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      phoneNumber: json['phoneNumber'] as String? ?? '',
      website: json['website'] as String? ?? '',
      openingHours:
          (json['openingHours'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      requiresBooking: json['requires_booking'] as bool? ?? false,
      restrictions:
          (json['restrictions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isFavourite: json['is_favourite'] as bool? ?? false,
      openingSlots:
          (json['opening_slots'] as List<dynamic>?)
              ?.map((e) => OpeningSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activeDeals:
          (json['active_deals'] as List<dynamic>?)
              ?.map((e) => Discount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      slug: json['slug'] as String?,
      leaderboardScore: _parseDouble(json['leaderboard_score']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'cuisine': cuisine,
      if (occupancy != null) 'occupancy': occupancy,
      'rating': rating,
      'reviewCount': reviewCount,
      'distance': distance,
      if (distanceMiles != null) 'distance_miles': distanceMiles,
      'discount': discount.toJson(),
      'images': images,
      'phoneNumber': phoneNumber,
      'website': website,
      'openingHours': openingHours,
      'requiresBooking': requiresBooking,
      'restrictions': restrictions,
      'leaderboard_score': leaderboardScore,
      if (slug != null) 'slug': slug,
    };
  }
}

/// Discount model
class Discount {
  final String type; // '2for1', 'percentage', 'fixed'
  final double? percentage;
  final double? fixedAmount;
  final String description;
  final String? title;
  final List<String> validDays;
  final String? validTime;
  final int? id;

  Discount({
    required this.type,
    this.percentage,
    this.fixedAmount,
    required this.description,
    this.title,
    this.validDays = const [],
    this.validTime,
    this.id,
  });

  String get displayText {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    switch (type) {
      case '2for1':
        return '2 FOR 1';
      case 'percentage':
        return '${percentage?.toInt()}% OFF';
      case 'fixed':
        return '£${fixedAmount?.toStringAsFixed(0)} OFF';
      default:
        return description;
    }
  }

  factory Discount.fromJson(Map<String, dynamic> json) {
    // Handle different API formats
    final type =
        json['type'] as String? ?? json['deal_type'] as String? ?? 'none';
    final percentage =
        _parseDouble(json['percentage']) ??
        _parseDouble(json['discount_percentage']);
    final fixedAmount =
        _parseDouble(json['fixedAmount']) ??
        _parseDouble(json['discount_amount']);
    final title = json['title'] as String?;
    final description = json['description'] as String? ?? '';

    return Discount(
      type: type,
      percentage: percentage,
      fixedAmount: fixedAmount,
      description: description,
      title: title,
      validDays:
          (json['validDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      validTime: json['validTime'] as String?,
      id: json['id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'percentage': percentage,
      'fixedAmount': fixedAmount,
      'description': description,
      'title': title,
      'validDays': validDays,
      'validTime': validTime,
    };
  }
}
