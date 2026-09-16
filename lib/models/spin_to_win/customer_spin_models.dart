import '../../config/environment.dart';
import '../image_variants.dart';

int _parseJsonInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<CustomerSpinSlice> _parseSlices(dynamic rawSlices) {
  if (rawSlices is! List) return [];
  final parsed = rawSlices
      .whereType<Map<String, dynamic>>()
      .map(CustomerSpinSlice.fromJson)
      .toList();
  parsed.sort((a, b) => a.sliceIndex.compareTo(b.sliceIndex));
  return parsed;
}

class CustomerSpinSlice {
  final int id;
  final String title;
  final String itemType; // "promocode", "discount", "empty", "points"
  final int sliceIndex;
  final String icon;
  final String? image;
  final String promoCodeValue;

  CustomerSpinSlice({
    required this.id,
    required this.title,
    required this.itemType,
    required this.sliceIndex,
    this.icon = '',
    this.image,
    this.promoCodeValue = '',
  });

  bool get isEmpty => itemType == 'empty';

  String? get displayImage {
    if (image == null || image!.isEmpty) return null;
    if (image!.startsWith('http://') || image!.startsWith('https://')) {
      return image;
    }
    return '${Environment.baseUrl}$image';
  }

  factory CustomerSpinSlice.fromJson(Map<String, dynamic> json) {
    return CustomerSpinSlice(
      id: _parseJsonInt(json['id']),
      title: json['title'] as String? ?? '',
      itemType: json['item_type'] as String? ?? 'empty',
      sliceIndex: _parseJsonInt(json['slice_index']),
      icon: json['icon'] as String? ?? '',
      image: parseApiImageUrl(json['image'] ?? json['image_url']),
      promoCodeValue: json['promo_code_value'] as String? ?? '',
    );
  }
}

class SpinCampaignWheel {
  final int campaignId;
  final String title;
  final String description;
  final int maxSpinsPerDay;
  final int remainingSpinsToday;
  final List<CustomerSpinSlice> slices;

  SpinCampaignWheel({
    required this.campaignId,
    this.title = '',
    this.description = '',
    this.maxSpinsPerDay = 0,
    this.remainingSpinsToday = 0,
    this.slices = const [],
  });

  factory SpinCampaignWheel.fromJson(Map<String, dynamic> json) {
    return SpinCampaignWheel(
      campaignId: _parseJsonInt(json['campaign_id'] ?? json['id']),
      title: json['title'] as String? ?? 'Spin to Win',
      description: json['description'] as String? ?? '',
      maxSpinsPerDay: _parseJsonInt(json['max_spins_per_day'], fallback: 1),
      remainingSpinsToday: _parseJsonInt(json['remaining_spins_today']),
      slices: _parseSlices(json['slices']),
    );
  }
}

class SpinWheelResponse {
  final List<SpinCampaignWheel> campaigns;
  final String? message;

  SpinWheelResponse({
    this.campaigns = const [],
    this.message,
  });

  bool get isActive => campaigns.isNotEmpty;

  bool get hasSpinsRemaining =>
      campaigns.any((campaign) => campaign.remainingSpinsToday > 0);

  factory SpinWheelResponse.fromJson(Map<String, dynamic> json) {
    final rawCampaigns = json['campaigns'];
    if (rawCampaigns is List) {
      return SpinWheelResponse(
        campaigns: rawCampaigns
            .whereType<Map<String, dynamic>>()
            .map(SpinCampaignWheel.fromJson)
            .toList(),
        message: json['message'] as String?,
      );
    }

    // Legacy single-campaign payload
    final isActive = json['is_active'] as bool? ?? json['campaign_id'] != null;
    if (!isActive) {
      return SpinWheelResponse(
        campaigns: const [],
        message: json['message'] as String? ??
            'No active Spin to Win campaigns currently available.',
      );
    }

    return SpinWheelResponse(
      campaigns: [SpinCampaignWheel.fromJson(json)],
      message: json['message'] as String?,
    );
  }
}

class SpinResultResponse {
  final int resultId;
  final bool isWin;
  final int sliceIndex;
  final String title;
  final String itemType;
  final String promoCode;
  final String? image;
  final DateTime spunAt;

  SpinResultResponse({
    required this.resultId,
    required this.isWin,
    required this.sliceIndex,
    required this.title,
    required this.itemType,
    required this.promoCode,
    this.image,
    required this.spunAt,
  });

  String? get displayImage {
    if (image == null || image!.isEmpty) return null;
    if (image!.startsWith('http://') || image!.startsWith('https://')) {
      return image;
    }
    return '${Environment.baseUrl}$image';
  }

  factory SpinResultResponse.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return SpinResultResponse(
      resultId: json['result_id'] as int? ?? json['id'] as int? ?? 0,
      isWin: json['is_win'] as bool? ?? false,
      sliceIndex: json['slice_index'] as int? ?? 0,
      title: json['title'] as String? ?? json['item_title'] as String? ?? '',
      itemType: json['item_type'] as String? ?? 'empty',
      promoCode: json['promo_code'] as String? ?? '',
      image: parseApiImageUrl(json['image'] ?? json['image_url']),
      spunAt: parseDate(json['spun_at']),
    );
  }
}

class CustomerSpinPrize {
  final int id;
  final String itemTitle;
  final String promoCode;
  final DateTime spunAt;

  CustomerSpinPrize({
    required this.id,
    required this.itemTitle,
    required this.promoCode,
    required this.spunAt,
  });

  factory CustomerSpinPrize.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CustomerSpinPrize(
      id: json['id'] as int? ?? 0,
      itemTitle: json['item_title'] as String? ?? json['title'] as String? ?? '',
      promoCode: json['promo_code'] as String? ?? '',
      spunAt: parseDate(json['spun_at']),
    );
  }
}
