class UserSpinResult {
  final int id;
  final dynamic user; // User ID or username object
  final int campaign;
  final int? item;
  final String itemTitle;
  final bool isWin;
  final String promoCode;
  final DateTime spunAt;
  final DateTime? claimedAt;

  UserSpinResult({
    required this.id,
    required this.user,
    required this.campaign,
    this.item,
    this.itemTitle = '',
    this.isWin = false,
    this.promoCode = '',
    required this.spunAt,
    this.claimedAt,
  });

  factory UserSpinResult.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      return null;
    }

    return UserSpinResult(
      id: json['id'] as int? ?? 0,
      user: json['user'],
      campaign: json['campaign'] as int? ?? 0,
      item: json['item'] as int?,
      itemTitle: json['item_title'] as String? ?? '',
      isWin: json['is_win'] as bool? ?? false,
      promoCode: json['promo_code'] as String? ?? '',
      spunAt: parseDate(json['spun_at']),
      claimedAt: parseNullableDate(json['claimed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'campaign': campaign,
      'item': item,
      'item_title': itemTitle,
      'is_win': isWin,
      'promo_code': promoCode,
      'spun_at': spunAt.toIso8601String(),
      'claimed_at': claimedAt?.toIso8601String(),
    };
  }
}
