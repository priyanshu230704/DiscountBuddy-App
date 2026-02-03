import 'package:flutter/foundation.dart';

/// Stat representation for the user profile
class ProfileStats {
  final int dealsClaimed;
  final double moneySaved;
  final String userLevel;
  final int restaurantsVisited;
  final int citiesVisited;
  final int favouriteRestaurants;
  final int reviewsWritten;

  ProfileStats({
    required this.dealsClaimed,
    required this.moneySaved,
    required this.userLevel,
    required this.restaurantsVisited,
    required this.citiesVisited,
    required this.favouriteRestaurants,
    required this.reviewsWritten,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      dealsClaimed: json['deals_claimed'] as int? ?? 0,
      moneySaved: (json['money_saved'] as num?)?.toDouble() ?? 0.0,
      userLevel: json['user_level'] as String? ?? 'Bronze',
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
      id: json['id'] as int? ?? 0,
      restaurantId: json['restaurant'] as int? ?? 0,
      restaurantName: json['restaurant_name'] as String? ?? '',
      restaurantSlug: json['restaurant_slug'] as String? ?? '',
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
