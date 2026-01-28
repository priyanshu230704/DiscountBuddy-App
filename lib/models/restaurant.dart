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
  final double rating;
  final int reviewCount;
  final double distance; // in km
  final Discount discount;
  final List<String> images;
  final String phoneNumber;
  final String website;
  final List<String> openingHours;
  final bool requiresBooking;
  final List<String> restrictions;
  final String? slug; // Optional slug for API calls
  final int? priceRange; // Price range 1-4
  final String? postcode;
  final String? email;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.cuisine,
    required this.rating,
    required this.reviewCount,
    required this.distance,
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
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      cuisine: json['cuisine'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      discount: Discount.fromJson(json['discount'] as Map<String, dynamic>),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      phoneNumber: json['phoneNumber'] as String? ?? '',
      website: json['website'] as String? ?? '',
      openingHours: (json['openingHours'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      requiresBooking: json['requiresBooking'] as bool? ?? false,
      restrictions: (json['restrictions'] as List<dynamic>?)
              ?.map((e) => e as String)
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
      'rating': rating,
      'reviewCount': reviewCount,
      'distance': distance,
      'discount': discount.toJson(),
      'images': images,
      'phoneNumber': phoneNumber,
      'website': website,
      'openingHours': openingHours,
      'requiresBooking': requiresBooking,
      'restrictions': restrictions,
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
  final List<String> validDays;
  final String? validTime;

  Discount({
    required this.type,
    this.percentage,
    this.fixedAmount,
    required this.description,
    this.validDays = const [],
    this.validTime,
  });

  String get displayText {
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
    return Discount(
      type: json['type'] as String,
      percentage: (json['percentage'] as num?)?.toDouble(),
      fixedAmount: (json['fixedAmount'] as num?)?.toDouble(),
      description: json['description'] as String,
      validDays: (json['validDays'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      validTime: json['validTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'percentage': percentage,
      'fixedAmount': fixedAmount,
      'description': description,
      'validDays': validDays,
      'validTime': validTime,
    };
  }
}

