import '../../config/environment.dart';

class AppBanner {
  final int id;
  final String? title;
  final String? body;
  final String ctaUrl;
  final int priority;
  final bool isVisible;
  final String? imageMedium;
  final String? imageLarge;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppBanner({
    required this.id,
    this.title,
    this.body,
    this.ctaUrl = '',
    this.priority = 0,
    this.isVisible = true,
    this.imageMedium,
    this.imageLarge,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Alias getters for backwards compatibility
  String get subtitle => body ?? '';
  bool get isActive => isVisible;
  int get displayOrder => priority;

  String? get displayImageMedium {
    if (imageMedium == null || imageMedium!.isEmpty) return null;
    if (imageMedium!.startsWith('http://') || imageMedium!.startsWith('https://')) {
      return imageMedium;
    }
    return '${Environment.baseUrl}$imageMedium';
  }

  String? get displayImageLarge {
    String? raw = (imageLarge != null && imageLarge!.isNotEmpty) ? imageLarge : imageMedium;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return '${Environment.baseUrl}$raw';
  }

  String? get displayImage => displayImageMedium ?? displayImageLarge;

  factory AppBanner.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
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
    } else if (json['image_url'] is String) {
      medium = json['image_url'] as String;
      large = json['image_url'] as String;
    }

    final isVisibleVal = json['is_visible'] as bool? ?? json['is_active'] as bool? ?? true;
    final priorityVal = json['priority'] as int? ?? json['display_order'] as int? ?? 0;
    final bodyVal = json['body'] as String? ?? json['subtitle'] as String?;

    return AppBanner(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String?,
      body: bodyVal,
      ctaUrl: json['cta_url'] as String? ?? json['target_value'] as String? ?? '',
      priority: priorityVal,
      isVisible: isVisibleVal,
      imageMedium: medium,
      imageLarge: large,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'cta_url': ctaUrl,
      'priority': priority,
      'is_visible': isVisible,
      'image': {
        'medium': imageMedium,
        'large': imageLarge,
      },
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
