import '../../config/environment.dart';

class AdminNotificationCampaign {
  final String id;
  final String title;
  final String message;
  final String audience;
  final int? restaurant;
  final String? restaurantName;
  final String? restaurantSlug;
  final String status;
  final String? scheduledAt;
  final int recipientCount;
  final String? errorMessage;
  final String? imageMedium;
  final String? imageLarge;
  final DateTime createdAt;

  AdminNotificationCampaign({
    required this.id,
    required this.title,
    required this.message,
    required this.audience,
    this.restaurant,
    this.restaurantName,
    this.restaurantSlug,
    required this.status,
    this.scheduledAt,
    required this.recipientCount,
    this.errorMessage,
    this.imageMedium,
    this.imageLarge,
    required this.createdAt,
  });

  String get audienceLabel {
    switch (audience) {
      case 'restaurant_favourites':
        return 'Restaurant favourites';
      default:
        return 'All customers';
    }
  }

  String? get displayImage {
    final raw = (imageLarge != null && imageLarge!.isNotEmpty) ? imageLarge : imageMedium;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '${Environment.baseUrl}$raw';
  }

  factory AdminNotificationCampaign.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawImage = json['image'];
    String? medium;
    String? large;
    if (rawImage is Map<String, dynamic>) {
      medium = rawImage['medium'] as String?;
      large = rawImage['large'] as String?;
    } else if (rawImage is String) {
      medium = rawImage;
      large = rawImage;
    }

    return AdminNotificationCampaign(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      audience: json['audience'] as String? ?? 'all_customers',
      restaurant: json['restaurant'] is int
          ? json['restaurant'] as int
          : int.tryParse('${json['restaurant'] ?? ''}'),
      restaurantName: json['restaurant_name'] as String?,
      restaurantSlug: json['restaurant_slug'] as String?,
      status: json['status'] as String? ?? 'queued',
      scheduledAt: json['scheduled_at'] as String?,
      recipientCount: json['recipient_count'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
      imageMedium: medium,
      imageLarge: large,
      createdAt: parseDate(json['created_at']),
    );
  }
}
