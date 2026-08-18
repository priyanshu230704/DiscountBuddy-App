import '../../config/environment.dart';

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
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      itemType: json['item_type'] as String? ?? 'empty',
      sliceIndex: json['slice_index'] as int? ?? 0,
      icon: json['icon'] as String? ?? '',
      image: json['image'] as String?,
      promoCodeValue: json['promo_code_value'] as String? ?? '',
    );
  }
}

class SpinWheelResponse {
  final bool isActive;
  final String? message;
  final int? campaignId;
  final String? title;
  final String? description;
  final int maxSpinsPerDay;
  final int remainingSpinsToday;
  final List<CustomerSpinSlice> slices;

  SpinWheelResponse({
    required this.isActive,
    this.message,
    this.campaignId,
    this.title,
    this.description,
    this.maxSpinsPerDay = 0,
    this.remainingSpinsToday = 0,
    this.slices = const [],
  });

  factory SpinWheelResponse.fromJson(Map<String, dynamic> json) {
    final isActive = json['is_active'] as bool? ?? false;
    if (!isActive) {
      return SpinWheelResponse(
        isActive: false,
        message: json['message'] as String? ?? 'No active Spin to Win campaign currently available.',
      );
    }

    final rawSlices = json['slices'];
    List<CustomerSpinSlice> parsedSlices = [];
    if (rawSlices is List) {
      parsedSlices = rawSlices
          .whereType<Map<String, dynamic>>()
          .map((s) => CustomerSpinSlice.fromJson(s))
          .toList();
      // Sort by slice_index
      parsedSlices.sort((a, b) => a.sliceIndex.compareTo(b.sliceIndex));
    }

    return SpinWheelResponse(
      isActive: true,
      campaignId: json['campaign_id'] as int?,
      title: json['title'] as String? ?? 'Spin to Win',
      description: json['description'] as String? ?? '',
      maxSpinsPerDay: json['max_spins_per_day'] as int? ?? 1,
      remainingSpinsToday: json['remaining_spins_today'] as int? ?? 0,
      slices: parsedSlices,
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
  final DateTime spunAt;

  SpinResultResponse({
    required this.resultId,
    required this.isWin,
    required this.sliceIndex,
    required this.title,
    required this.itemType,
    required this.promoCode,
    required this.spunAt,
  });

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
