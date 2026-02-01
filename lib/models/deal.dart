/// Deal model for NeoTaste-style deals
class Deal {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImageUrl;
  final String title;
  final String description;
  final String discountText; // e.g., "2-for-1 Main Course"
  final List<String> validDays; // e.g., ["Monday", "Tuesday"]
  final String? validTime; // e.g., "12:00 - 15:00"
  final DateTime? expiryDate;
  final DealStatus status; // active, used, expired
  final DateTime? redeemedAt;

  Deal({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImageUrl,
    required this.title,
    required this.description,
    required this.discountText,
    this.validDays = const [],
    this.validTime,
    this.expiryDate,
    required this.status,
    this.redeemedAt,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      restaurantName: json['restaurantName'] as String,
      restaurantImageUrl: json['restaurantImageUrl'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      discountText: json['discountText'] as String,
      validDays: (json['validDays'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      validTime: json['validTime'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      status: DealStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => DealStatus.active,
      ),
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.parse(json['redeemedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantImageUrl': restaurantImageUrl,
      'title': title,
      'description': description,
      'discountText': discountText,
      'validDays': validDays,
      'validTime': validTime,
      'expiryDate': expiryDate?.toIso8601String(),
      'status': status.toString().split('.').last,
      'redeemedAt': redeemedAt?.toIso8601String(),
    };
  }
}

enum DealStatus {
  active,
  used,
  expired,
}
