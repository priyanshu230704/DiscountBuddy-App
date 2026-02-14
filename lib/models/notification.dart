class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final Map<String, dynamic>? payload;
  final String? sourceId;
  final String? sourceType;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    this.payload,
    this.sourceId,
    this.sourceType,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      notificationType: json['notification_type'] as String,
      isRead: json['is_read'] as bool,
      payload: json['payload'] as Map<String, dynamic>?,
      sourceId: json['source_id'] as String?,
      sourceType: json['source_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'notification_type': notificationType,
      'is_read': isRead,
      'payload': payload,
      'source_id': sourceId,
      'source_type': sourceType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? notificationType,
    bool? isRead,
    Map<String, dynamic>? payload,
    String? sourceId,
    String? sourceType,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<NotificationModel> results;

  NotificationListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DeviceToken {
  final String id;
  final String token;
  final String deviceType;
  final bool isActive;
  final DateTime createdAt;

  DeviceToken({
    required this.id,
    required this.token,
    required this.deviceType,
    required this.isActive,
    required this.createdAt,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    return DeviceToken(
      id: json['id'] as String,
      token: json['token'] as String,
      deviceType: json['device_type'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'device_type': deviceType,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Notification types enum for type safety
class NotificationType {
  static const String bookingConfirmed = 'BOOKING_CONFIRMED';
  static const String favDeal = 'FAV_DEAL';
  static const String dealRedeemed = 'DEAL_REDEEMED';
  static const String system = 'SYSTEM';
}
