class DealRedemption {
  final int id;
  final RedeemedDeal deal;
  final DateTime usedAt;
  final bool restaurantConfirmed;
  final String? notes;
  final String? redemptionCode;
  final String? qrCode;
  final String? qrCodeUrl;
  final bool isRedeemed;
  final DateTime? redeemedAt;
  final double? price;
  final int? peopleCount;
  final double? discountAmountSaved;
  final double? finalBillAmount;
  final DateTime createdAt;

  DealRedemption({
    required this.id,
    required this.deal,
    required this.usedAt,
    required this.restaurantConfirmed,
    this.notes,
    this.redemptionCode,
    this.qrCode,
    this.qrCodeUrl,
    required this.isRedeemed,
    this.redeemedAt,
    this.price,
    this.peopleCount,
    this.discountAmountSaved,
    this.finalBillAmount,
    required this.createdAt,
  });

  factory DealRedemption.fromJson(Map<String, dynamic> json) {
    return DealRedemption(
      id: json['id'] as int? ?? 0,
      deal: RedeemedDeal.fromJson(json['deal'] as Map<String, dynamic>),
      usedAt: DateTime.tryParse(json['used_at'] ?? '') ?? DateTime.now(),
      restaurantConfirmed: json['restaurant_confirmed'] as bool? ?? false,
      notes: json['notes'] as String?,
      redemptionCode: json['redemption_code'] as String?,
      qrCode: json['qr_code'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
      isRedeemed: json['is_redeemed'] as bool? ?? false,
      redeemedAt: json['redeemed_at'] != null
          ? DateTime.tryParse(json['redeemed_at'])
          : null,
      price: _parseDouble(json['price']),
      peopleCount: json['people_count'] as int?,
      discountAmountSaved: _parseDouble(json['discount_amount_saved']),
      finalBillAmount: _parseDouble(json['final_bill_amount']),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class RedeemedDeal {
  final int id;
  final String title;
  final String description;
  final String dealType;
  final String restaurantName;
  final String restaurantSlug;
  final String cityName;
  final double? discountPercentage;
  final String? discountAmount;
  final String? minimumSpend;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isFeatured;
  final String? primaryImage;
  final bool isActive;
  final DateTime? createdAt;

  RedeemedDeal({
    required this.id,
    required this.title,
    required this.description,
    required this.dealType,
    required this.restaurantName,
    required this.restaurantSlug,
    required this.cityName,
    this.discountPercentage,
    this.discountAmount,
    this.minimumSpend,
    this.startDate,
    this.endDate,
    required this.isFeatured,
    this.primaryImage,
    required this.isActive,
    this.createdAt,
  });

  factory RedeemedDeal.fromJson(Map<String, dynamic> json) {
    return RedeemedDeal(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Deal',
      description: json['description'] as String? ?? '',
      dealType: json['deal_type'] as String? ?? 'percentage',
      restaurantName:
          json['restaurant_name'] as String? ?? 'Unknown Restaurant',
      restaurantSlug: json['restaurant_slug'] as String? ?? '',
      cityName: json['city_name'] as String? ?? '',
      discountPercentage: _parseDouble(json['discount_percentage']),
      discountAmount: json['discount_amount'] as String?,
      minimumSpend: json['minimum_spend'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      isFeatured: json['is_featured'] as bool? ?? false,
      primaryImage: json['primary_image'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

/// Helper to safely parse a value to double
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
