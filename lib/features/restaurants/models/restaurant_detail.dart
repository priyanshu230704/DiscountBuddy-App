import 'package:discount_buddy/features/restaurants/models/restaurant.dart';
import 'package:discount_buddy/features/restaurants/models/review.dart';
import 'package:discount_buddy/features/restaurants/models/menu_item.dart';

/// Restaurant Detail model containing full restaurant data with reviews and menu
class RestaurantDetail {
  final Restaurant restaurant;
  final List<Review> reviews;
  final List<MenuCategory> menuCategories;

  RestaurantDetail({
    required this.restaurant,
    required this.reviews,
    required this.menuCategories,
  });
}
