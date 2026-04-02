/// Cuisine model
class Cuisine {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  Cuisine({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) {
    return Cuisine(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
    };
  }
}

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

/// Facility model
class Facility {
  final int id;
  final String name;
  final String slug;
  final String icon;
  final bool isActive;

  Facility({
    required this.id,
    required this.name,
    required this.slug,
    this.icon = '',
    this.isActive = true,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
      'is_active': isActive,
    };
  }
}

/// Restaurant Image model
class RestaurantImage {
  final int id;
  final String image;
  final String imageUrl;
  final String altText;
  final String imageType; // gallery, menu
  final bool isPrimary;
  final int order;

  RestaurantImage({
    required this.id,
    required this.image,
    required this.imageUrl,
    this.altText = '',
    this.imageType = 'gallery',
    this.isPrimary = false,
    this.order = 0,
  });

  factory RestaurantImage.fromJson(Map<String, dynamic> json) {
    return RestaurantImage(
      id: json['id'] as int? ?? 0,
      image: json['image'] as String? ?? json['image_url'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['image'] as String? ?? '',
      altText: json['alt_text'] as String? ?? '',
      imageType: json['image_type'] as String? ?? 'gallery',
      isPrimary: json['is_primary'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'image_url': imageUrl,
      'alt_text': altText,
      'image_type': imageType,
      'is_primary': isPrimary,
      'order': order,
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
  final bool hasUserReviewed;
  final List<OpeningSlot> openingSlots;
  final List<Discount> activeDeals;
  final List<Facility> facilities;
  final String menuType; // structured, image
  final List<RestaurantImage> restaurantImages;
  final List<Cuisine> cuisines;

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
    this.hasUserReviewed = false,
    this.openingSlots = const [],
    this.activeDeals = const [],
    this.facilities = const [],
    this.leaderboardScore = 0.0,
    this.menuType = 'structured',
    this.restaurantImages = const [],
    this.cuisines = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final List<Discount> activeDeals = (json['active_deals'] as List<dynamic>?)
            ?.map((e) => Discount.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Discount>[];

    final List<Cuisine> cuisines = (json['cuisines'] as List<dynamic>?)
            ?.map((e) => Cuisine.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Cuisine>[];

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
      rating:
          _parseDouble(json['average_rating']) ??
          _parseDouble(json['rating']) ??
          0.0,
      reviewCount:
          _parseInt(json['review_count']) ??
          _parseInt(json['reviewCount']) ??
          0,
      distance: _parseDouble(json['distance']) ?? 0.0,
      distanceMiles: _parseDouble(json['distance_miles']),
      activeDeals: activeDeals,
      discount: json['discount'] != null
          ? Discount.fromJson(json['discount'] as Map<String, dynamic>)
          : (activeDeals.isNotEmpty ? activeDeals.first : Discount(type: 'none', description: '')),
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
      cuisines: cuisines,
      hasUserReviewed: json['has_user_reviewed'] as bool? ?? false,
      openingSlots:
          (json['opening_slots'] as List<dynamic>?)
              ?.map((e) => OpeningSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      facilities:
          (json['facilities'] as List<dynamic>?)
               ?.map((e) => Facility.fromJson(e as Map<String, dynamic>))
               .toList() ??
          [],
      slug: json['slug'] as String?,
      leaderboardScore: _parseDouble(json['leaderboard_score']) ?? 0.0,
      menuType: json['menu_type'] as String? ?? 'structured',
      restaurantImages:
          (json['images'] as List<dynamic>?)
              ?.map((e) => RestaurantImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
      'phoneNumber': phoneNumber,
      'website': website,
      'openingHours': openingHours,
      'requiresBooking': requiresBooking,
      'restrictions': restrictions,
      'isFavourite': isFavourite,
      'hasUserReviewed': hasUserReviewed,
      'leaderboard_score': leaderboardScore,
      'facilities': facilities.map((e) => e.toJson()).toList(),
      'menu_type': menuType,
      'images': restaurantImages.map((e) => e.toJson()).toList(),
      if (slug != null) 'slug': slug,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? address,
    double? latitude,
    double? longitude,
    String? cuisine,
    String? occupancy,
    double? rating,
    int? reviewCount,
    double? distance,
    double? distanceMiles,
    Discount? discount,
    List<String>? images,
    String? phoneNumber,
    String? website,
    List<String>? openingHours,
    bool? requiresBooking,
    List<String>? restrictions,
    double? leaderboardScore,
    String? slug,
    int? priceRange,
    String? postcode,
    String? email,
    bool? isFavourite,
    bool? hasUserReviewed,
    List<OpeningSlot>? openingSlots,
    List<Discount>? activeDeals,
    List<Facility>? facilities,
    String? menuType,
    List<RestaurantImage>? restaurantImages,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cuisine: cuisine ?? this.cuisine,
      occupancy: occupancy ?? this.occupancy,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      distance: distance ?? this.distance,
      distanceMiles: distanceMiles ?? this.distanceMiles,
      discount: discount ?? this.discount,
      images: images ?? this.images,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      openingHours: openingHours ?? this.openingHours,
      requiresBooking: requiresBooking ?? this.requiresBooking,
      restrictions: restrictions ?? this.restrictions,
      leaderboardScore: leaderboardScore ?? this.leaderboardScore,
      slug: slug ?? this.slug,
      priceRange: priceRange ?? this.priceRange,
      postcode: postcode ?? this.postcode,
      email: email ?? this.email,
      isFavourite: isFavourite ?? this.isFavourite,
      hasUserReviewed: hasUserReviewed ?? this.hasUserReviewed,
      openingSlots: openingSlots ?? this.openingSlots,
      activeDeals: activeDeals ?? this.activeDeals,
      facilities: facilities ?? this.facilities,
      menuType: menuType ?? this.menuType,
      restaurantImages: restaurantImages ?? this.restaurantImages,
      cuisines: cuisines ?? this.cuisines,
    );
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
  final String termsAndConditions;
  final int maxPerUser;
  final double? minimumSpendAmount;

  Discount({
    required this.type,
    this.percentage,
    this.fixedAmount,
    required this.description,
    this.title,
    this.validDays = const [],
    this.validTime,
    this.id,
    this.termsAndConditions = '',
    this.maxPerUser = 1,
    this.minimumSpendAmount,
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
    final minimumSpendAmount = 
        _parseDouble(json['minimumSpendAmount']) ??
        _parseDouble(json['minimum_spend_amount']) ??
        _parseDouble(json['minimum_spend']);

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
      termsAndConditions: json['terms_and_conditions'] as String? ?? '',
      maxPerUser: json['max_per_user'] as int? ?? 1,
      minimumSpendAmount: minimumSpendAmount,
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
      'minimumSpendAmount': minimumSpendAmount,
    };
  }
}
