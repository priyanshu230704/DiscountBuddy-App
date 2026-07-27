class City {
  final int id;
  final String name;
  final String slug;
  final double latitude;
  final double longitude;
  final int restaurantsCount;
  final int activeDealsCount;

  City({
    required this.id,
    required this.name,
    required this.slug,
    required this.latitude,
    required this.longitude,
    required this.restaurantsCount,
    required this.activeDealsCount,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      slug: json["slug"] ?? "",
      latitude: double.tryParse(json["latitude"]?.toString() ?? "") ?? 0.0,
      longitude: double.tryParse(json["longitude"]?.toString() ?? "") ?? 0.0,
      restaurantsCount: json["restaurants_count"] ?? 0,
      activeDealsCount: json["active_deals_count"] ?? 0,
    );
  }
}
