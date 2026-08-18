import '../../config/environment.dart';

enum SpinItemType {
  promocode, // "promocode"
  discount,  // "discount"
  empty,     // "empty"
  points,    // "points"
}

extension SpinItemTypeExtension on SpinItemType {
  String toValue() {
    switch (this) {
      case SpinItemType.promocode:
        return 'promocode';
      case SpinItemType.discount:
        return 'discount';
      case SpinItemType.empty:
        return 'empty';
      case SpinItemType.points:
        return 'points';
    }
  }

  static SpinItemType fromValue(String? value) {
    switch (value) {
      case 'promocode':
        return SpinItemType.promocode;
      case 'discount':
        return SpinItemType.discount;
      case 'points':
        return SpinItemType.points;
      case 'empty':
      default:
        return SpinItemType.empty;
    }
  }
}

class SpinItem {
  final int id;
  final int campaign;
  final String title;
  final String description;
  final String icon;
  final String? image;
  final SpinItemType itemType;
  final String promoCodeValue;
  final double? discountPercentage;
  final int minSpinsBeforeWin;
  final int? stockLimit;
  final int timesWon;
  final int probabilityWeight;
  final int sliceIndex;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpinItem({
    required this.id,
    required this.campaign,
    required this.title,
    this.description = '',
    this.icon = '🎁',
    this.image,
    required this.itemType,
    this.promoCodeValue = '',
    this.discountPercentage,
    this.minSpinsBeforeWin = 0,
    this.stockLimit,
    this.timesWon = 0,
    this.probabilityWeight = 10,
    this.sliceIndex = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String? get displayImage {
    if (image == null || image!.isEmpty) return null;
    if (image!.startsWith('http://') || image!.startsWith('https://')) {
      return image;
    }
    return '${Environment.baseUrl}$image';
  }

  factory SpinItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return SpinItem(
      id: json['id'] as int? ?? 0,
      campaign: json['campaign'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🎁',
      image: json['image'] as String?,
      itemType: SpinItemTypeExtension.fromValue(json['item_type'] as String?),
      promoCodeValue: json['promo_code_value'] as String? ?? '',
      discountPercentage: parseDouble(json['discount_percentage']),
      minSpinsBeforeWin: json['min_spins_before_win'] as int? ?? 0,
      stockLimit: json['stock_limit'] as int?,
      timesWon: json['times_won'] as int? ?? 0,
      probabilityWeight: json['probability_weight'] as int? ?? 10,
      sliceIndex: json['slice_index'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaign': campaign,
      'title': title,
      'description': description,
      'icon': icon,
      'image': image,
      'item_type': itemType.toValue(),
      'promo_code_value': promoCodeValue,
      'discount_percentage': discountPercentage,
      'min_spins_before_win': minSpinsBeforeWin,
      'stock_limit': stockLimit,
      'times_won': timesWon,
      'probability_weight': probabilityWeight,
      'slice_index': sliceIndex,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
