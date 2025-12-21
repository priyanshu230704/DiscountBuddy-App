/// Voucher model
class Voucher {
  final int id;
  final String code;
  final String title;
  final String description;
  final Merchant merchant;
  final Category? category;
  final double discountPercent;
  final String originalPrice;
  final String salePrice;
  final DateTime startDate;
  final DateTime endDate;
  final int totalQuantity;
  final int soldQuantity;
  final int maxPerUser;
  final int remainingQuantity;

  Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.merchant,
    this.category,
    required this.discountPercent,
    required this.originalPrice,
    required this.salePrice,
    required this.startDate,
    required this.endDate,
    required this.totalQuantity,
    required this.soldQuantity,
    required this.maxPerUser,
    required this.remainingQuantity,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as int,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      merchant: Merchant.fromJson(json['merchant'] as Map<String, dynamic>),
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      discountPercent: (json['discount_percent'] as num).toDouble(),
      originalPrice: json['original_price'] as String,
      salePrice: json['sale_price'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalQuantity: json['total_quantity'] as int,
      soldQuantity: json['sold_quantity'] as int? ?? 0,
      maxPerUser: json['max_per_user'] as int? ?? 5,
      remainingQuantity: json['remaining_quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'merchant': merchant.toJson(),
      'category': category?.toJson(),
      'discount_percent': discountPercent,
      'original_price': originalPrice,
      'sale_price': salePrice,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_quantity': totalQuantity,
      'sold_quantity': soldQuantity,
      'max_per_user': maxPerUser,
      'remaining_quantity': remainingQuantity,
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

/// Merchant model
class Merchant {
  final int id;
  final String name;
  final bool verified;

  Merchant({
    required this.id,
    required this.name,
    required this.verified,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'] as int,
      name: json['name'] as String,
      verified: json['verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'verified': verified,
    };
  }
}

/// Category model
class Category {
  final int id;
  final String name;
  final String slug;

  Category({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

/// Paginated voucher response
class PaginatedVouchers {
  final int count;
  final String? next;
  final String? previous;
  final List<Voucher> results;

  PaginatedVouchers({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedVouchers.fromJson(Map<String, dynamic> json) {
    return PaginatedVouchers(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((item) => Voucher.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
