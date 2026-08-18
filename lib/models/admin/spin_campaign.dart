import 'spin_item.dart';

class SpinCampaign {
  final int id;
  final String title;
  final String description;
  final bool isActive;
  final int maxSpinsPerUserPerDay;
  final int totalSpinsCount;
  final List<SpinItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpinCampaign({
    required this.id,
    required this.title,
    this.description = '',
    this.isActive = true,
    this.maxSpinsPerUserPerDay = 1,
    this.totalSpinsCount = 0,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpinCampaign.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawItems = json['items'];
    List<SpinItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map<String, dynamic>>()
          .map((itemJson) => SpinItem.fromJson(itemJson))
          .toList();
    }

    return SpinCampaign(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      maxSpinsPerUserPerDay: json['max_spins_per_user_per_day'] as int? ?? 1,
      totalSpinsCount: json['total_spins_count'] as int? ?? 0,
      items: parsedItems,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_active': isActive,
      'max_spins_per_user_per_day': maxSpinsPerUserPerDay,
      'total_spins_count': totalSpinsCount,
      'items': items.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
