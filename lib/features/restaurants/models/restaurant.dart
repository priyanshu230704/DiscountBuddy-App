import 'package:discount_buddy/features/restaurants/models/image_variants.dart';

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
    return {'id': id, 'name': name, 'slug': slug, 'icon': icon};
  }
}

/// Restaurant Category model
class RestaurantCategory {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  RestaurantCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory RestaurantCategory.fromJson(Map<String, dynamic> json) {
    return RestaurantCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug, 'icon': icon};
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

  static List<OpeningSlot> fromHoursMap(Map<String, dynamic>? hoursMap) {
    if (hoursMap == null || hoursMap.isEmpty) return [];

    const dayOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    return dayOrder.map((dayKey) {
      final dayName = '${dayKey[0].toUpperCase()}${dayKey.substring(1)}';
      final value = hoursMap[dayKey]?.toString().trim() ?? '';

      if (value.isEmpty) {
        return OpeningSlot(
          dayName: dayName,
          openingTime: '',
          closingTime: '',
          isClosed: true,
        );
      }

      if (value.contains('-')) {
        final parts = value.split('-');
        final openingTime = parts.first.trim();
        final closingTime = parts.length > 1 ? parts[1].trim() : '';

        return OpeningSlot(
          dayName: dayName,
          openingTime: openingTime,
          closingTime: closingTime,
          isClosed: openingTime.isEmpty || closingTime.isEmpty,
        );
      }

      return OpeningSlot(
        dayName: dayName,
        openingTime: '',
        closingTime: '',
        isClosed: true,
      );
    }).toList();
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
  final ImageVariants image;
  final String altText;
  final String imageType; // gallery, menu
  final bool isPrimary;
  final int order;

  RestaurantImage({
    required this.id,
    required this.image,
    this.altText = '',
    this.imageType = 'gallery',
    this.isPrimary = false,
    this.order = 0,
  });

  // Convenience getter for backward compatibility
  String get imageUrl => image.urlFor(fullScreen: false) ?? '';

  factory RestaurantImage.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image'] ?? json['image_url'];
    ImageVariants parsedImage;
    if (rawImage is Map<String, dynamic>) {
      parsedImage = ImageVariants.fromJson(rawImage);
    } else if (rawImage is String) {
      parsedImage = ImageVariants(medium: rawImage, large: rawImage);
    } else {
      parsedImage = const ImageVariants();
    }

    return RestaurantImage(
      id: json['id'] as int? ?? 0,
      image: parsedImage,
      altText: json['alt_text'] as String? ?? '',
      imageType: json['image_type'] as String? ?? 'gallery',
      isPrimary: json['is_primary'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image.toJson(),
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
  final List<RestaurantCategory> categories;
  final bool verified;
  final bool isFeatured;
  final bool loyaltyCardEnabled;
  final int? loyaltyRequiredRedemptions;
  final String? loyaltyRewardDescription;
  final LoyaltyProgram? loyaltyProgram;

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
    this.categories = const [],
    this.verified = false,
    this.isFeatured = false,
    this.loyaltyCardEnabled = false,
    this.loyaltyRequiredRedemptions,
    this.loyaltyRewardDescription,
    this.loyaltyProgram,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final List<Discount> activeDeals =
        (json['active_deals'] as List<dynamic>?)
            ?.map((e) => Discount.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Discount>[];

    final List<Cuisine> cuisines =
        (json['cuisines'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => Cuisine.fromJson(e))
            .toList() ??
        <Cuisine>[];

    final List<RestaurantCategory> categories =
        (json['categories'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => RestaurantCategory.fromJson(e))
            .toList() ??
        <RestaurantCategory>[];

    final List<dynamic> rawImagesList = json['images'] as List<dynamic>? ?? [];
    List<RestaurantImage> parsedRestaurantImages = [];
    List<String> plainStringImages = [];

    for (var raw in rawImagesList) {
      if (raw is Map<String, dynamic>) {
        parsedRestaurantImages.add(RestaurantImage.fromJson(raw));
      } else if (raw is String) {
        plainStringImages.add(raw);
      }
    }

    parsedRestaurantImages.sort((a, b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return a.order.compareTo(b.order);
    });

    final List<String> sortedImageUrls = parsedRestaurantImages
        .map((e) => e.image.urlFor(fullScreen: true) ?? '')
        .where((u) => u.isNotEmpty)
        .toList();

    if (sortedImageUrls.isEmpty && plainStringImages.isNotEmpty) {
      sortedImageUrls.addAll(plainStringImages);
    } else {
      for (var plain in plainStringImages) {
        if (!sortedImageUrls.contains(plain)) {
          sortedImageUrls.add(plain);
        }
      }
    }

    final String primaryImageUrl = sortedImageUrls.isNotEmpty
        ? sortedImageUrls.first
        : (json['imageUrl'] as String? ?? json['image'] as String? ?? '');

    return Restaurant(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: primaryImageUrl,
      address: json['address'] as String? ?? '',
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
      cuisine:
          json['cuisine'] as String? ??
          (cuisines.isNotEmpty ? cuisines.map((e) => e.name).join(' • ') : ''),
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
          : (activeDeals.isNotEmpty
                ? activeDeals.first
                : Discount(type: 'none', description: '')),
      images: sortedImageUrls,
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
              ?.whereType<Map<String, dynamic>>()
              .map((e) => Facility.fromJson(e))
              .toList() ??
          [],
      slug: json['slug'] as String?,
      leaderboardScore: _parseDouble(json['leaderboard_score']) ?? 0.0,
      menuType: json['menu_type'] as String? ?? 'structured',
      restaurantImages: parsedRestaurantImages,
      categories: categories,
      verified: json['verified'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      loyaltyCardEnabled: (json['loyalty_card_enabled'] as bool? ?? false) ||
          (json['loyalty_program'] != null &&
              json['loyalty_program']['loyalty_card_enabled'] == true),
      loyaltyRequiredRedemptions:
          _parseInt(json['loyalty_required_redemptions']) ??
          (json['loyalty_program'] != null
              ? _parseInt(json['loyalty_program']['required_redemptions'])
              : null),
      loyaltyRewardDescription:
          (json['loyalty_reward_description'] as String?) ??
          (json['loyalty_program'] != null
              ? json['loyalty_program']['reward_description'] as String?
              : null),
      loyaltyProgram: json['loyalty_program'] != null
          ? LoyaltyProgram.fromJson(
              json['loyalty_program'] as Map<String, dynamic>,
            )
          : null,
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
      'categories': categories.map((e) => e.toJson()).toList(),
      'menu_type': menuType,
      'images': restaurantImages.map((e) => e.toJson()).toList(),
      'verified': verified,
      'is_featured': isFeatured,
      'loyalty_card_enabled': loyaltyCardEnabled,
      if (loyaltyRequiredRedemptions != null)
        'loyalty_required_redemptions': loyaltyRequiredRedemptions,
      if (loyaltyRewardDescription != null)
        'loyalty_reward_description': loyaltyRewardDescription,
      if (loyaltyProgram != null) 'loyalty_program': loyaltyProgram!.toJson(),
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
    List<RestaurantCategory>? categories,
    String? menuType,
    List<RestaurantImage>? restaurantImages,
    bool? verified,
    bool? isFeatured,
    bool? loyaltyCardEnabled,
    int? loyaltyRequiredRedemptions,
    String? loyaltyRewardDescription,
    LoyaltyProgram? loyaltyProgram,
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
      facilities: facilities,
      categories: categories ?? this.categories,
      menuType: menuType ?? this.menuType,
      restaurantImages: restaurantImages ?? this.restaurantImages,
      cuisines: cuisines,
      verified: verified ?? this.verified,
      isFeatured: isFeatured ?? this.isFeatured,
      loyaltyCardEnabled: loyaltyCardEnabled ?? this.loyaltyCardEnabled,
      loyaltyRequiredRedemptions:
          loyaltyRequiredRedemptions ?? this.loyaltyRequiredRedemptions,
      loyaltyRewardDescription:
          loyaltyRewardDescription ?? this.loyaltyRewardDescription,
      loyaltyProgram: loyaltyProgram ?? this.loyaltyProgram,
    );
  }
}

/// Discount model
class Discount {
  final String type; // '2for1', 'percentage', 'fixed'
  final double? percentage;
  final double? fixedAmount;
  final double? comboPrice;
  final String description;
  final String? shortDescription;
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
    this.comboPrice,
    required this.description,
    this.shortDescription,
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
        return '${percentage?.toInt() ?? 0}% OFF';
      case 'fixed':
        if (fixedAmount != null) {
          return '£${fixedAmount!.toStringAsFixed(0)} OFF';
        }
        return description.isNotEmpty ? description : 'Special offer';
      case 'combo':
        if (comboPrice != null) {
          return '£${comboPrice!.toStringAsFixed(0)} COMBO';
        }
        return description.isNotEmpty ? description : 'Combo';
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
    final comboPrice = _parseDouble(json['combo_price']);
    final title = json['title'] as String?;
    final description = json['description'] as String? ?? '';
    final shortDescription = json['short_description'] as String?;
    final minimumSpendAmount =
        _parseDouble(json['minimumSpendAmount']) ??
        _parseDouble(json['minimum_spend_amount']) ??
        _parseDouble(json['minimum_spend']);

    return Discount(
      type: type,
      percentage: percentage,
      fixedAmount: fixedAmount,
      comboPrice: comboPrice,
      description: description,
      shortDescription: shortDescription,
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
      'combo_price': comboPrice,
      'description': description,
      'short_description': shortDescription,
      'title': title,
      'validDays': validDays,
      'validTime': validTime,
      'minimumSpendAmount': minimumSpendAmount,
    };
  }
}

/// Loyalty Program Model
class LoyaltyProgram {
  final bool loyaltyCardEnabled;
  final int requiredRedemptions;
  final String rewardDescription;
  final int completedRedemptions;
  final int remainingRedemptions;
  final String progressText;
  final double progressPercentage;
  final bool isRewardEligible;
  final String? rewardEligibleAt;
  final int totalLifetimeRedemptions;
  final int rewardsEarned;
  final String? lastRewardClaimedAt;
  final String? rewardCode;
  final String? rewardQrCode;

  LoyaltyProgram({
    required this.loyaltyCardEnabled,
    required this.requiredRedemptions,
    required this.rewardDescription,
    required this.completedRedemptions,
    required this.remainingRedemptions,
    required this.progressText,
    required this.progressPercentage,
    required this.isRewardEligible,
    this.rewardEligibleAt,
    required this.totalLifetimeRedemptions,
    required this.rewardsEarned,
    this.lastRewardClaimedAt,
    this.rewardCode,
    this.rewardQrCode,
  });

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) {
    return LoyaltyProgram(
      loyaltyCardEnabled: json['loyalty_card_enabled'] as bool? ?? false,
      requiredRedemptions: json['required_redemptions'] as int? ?? 0,
      rewardDescription: json['reward_description'] as String? ?? '',
      completedRedemptions: json['completed_redemptions'] as int? ?? 0,
      remainingRedemptions: json['remaining_redemptions'] as int? ?? 0,
      progressText: json['progress_text'] as String? ?? '',
      progressPercentage: _parseDouble(json['progress_percentage']) ?? 0.0,
      isRewardEligible: json['is_reward_eligible'] as bool? ?? false,
      rewardEligibleAt: json['reward_eligible_at'] as String?,
      totalLifetimeRedemptions: json['total_lifetime_redemptions'] as int? ?? 0,
      rewardsEarned: json['rewards_earned'] as int? ?? 0,
      lastRewardClaimedAt: json['last_reward_claimed_at'] as String?,
      rewardCode: json['reward_code'] as String?,
      rewardQrCode: json['reward_qr_url'] as String? ?? json['reward_qr_code'] as String?,
    );
  }

  factory LoyaltyProgram.empty() {
    return LoyaltyProgram(
      loyaltyCardEnabled: false,
      requiredRedemptions: 0,
      rewardDescription: '',
      completedRedemptions: 0,
      remainingRedemptions: 0,
      progressText: '',
      progressPercentage: 0.0,
      isRewardEligible: false,
      totalLifetimeRedemptions: 0,
      rewardsEarned: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loyalty_card_enabled': loyaltyCardEnabled,
      'required_redemptions': requiredRedemptions,
      'reward_description': rewardDescription,
      'completed_redemptions': completedRedemptions,
      'remaining_redemptions': remainingRedemptions,
      'progress_text': progressText,
      'progress_percentage': progressPercentage,
      'is_reward_eligible': isRewardEligible,
      'reward_eligible_at': rewardEligibleAt,
      'total_lifetime_redemptions': totalLifetimeRedemptions,
      'rewards_earned': rewardsEarned,
      'last_reward_claimed_at': lastRewardClaimedAt,
      if (rewardCode != null) 'reward_code': rewardCode,
      if (rewardQrCode != null) 'reward_qr_code': rewardQrCode,
    };
  }
}
