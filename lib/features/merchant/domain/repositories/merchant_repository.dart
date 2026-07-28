import 'package:discount_buddy/core/domain/result.dart';

/// Intent-based merchant repository contract covering all merchant capabilities
abstract class MerchantRepository {
  // Dashboard & Analytics
  Future<Result<Map<String, dynamic>>> getMerchantDashboardStats({int? restaurantId});
  Future<Result<Map<String, dynamic>>> getMerchantAnalytics({
    int? restaurantId,
    int period,
  });

  // Restaurant Management
  Future<Result<List<Map<String, dynamic>>>> getMerchantRestaurants({
    int? page,
    String? search,
    String? ordering,
    int? cityId,
  });
  Future<Result<Map<String, dynamic>>> getRestaurantDetail(int restaurantId);
  Future<Result<Map<String, dynamic>>> createRestaurant(Map<String, dynamic> data);
  Future<Result<Map<String, dynamic>>> updateRestaurant(int restaurantId, Map<String, dynamic> data);
  Future<Result<void>> deleteRestaurant(int restaurantId);
  Future<Result<Map<String, dynamic>>> updateOccupancy(int restaurantId, String occupancy);

  // Restaurant Images
  Future<Result<Map<String, dynamic>>> uploadRestaurantImage({
    required int restaurantId,
    required String imagePath,
    required String imageType,
    String? altText,
    bool isPrimary,
  });
  Future<Result<void>> deleteRestaurantImage(int imageId);
  Future<Result<Map<String, dynamic>>> setPrimaryImage(int imageId);

  // Deal Management
  Future<Result<List<Map<String, dynamic>>>> getMerchantDeals({
    int? page,
    int? restaurantId,
    String? dealType,
    bool? isFeatured,
    String? search,
    String? ordering,
  });
  Future<Result<Map<String, dynamic>>> getDealDetails(int dealId);
  Future<Result<Map<String, dynamic>>> createDeal(Map<String, dynamic> data);
  Future<Result<Map<String, dynamic>>> updateDeal(int dealId, Map<String, dynamic> data);
  Future<Result<void>> deleteDeal(int dealId);
  Future<Result<Map<String, dynamic>>> toggleDealStatus(
    int dealId, {
    String? startDate,
    String? endDate,
  });

  // Menu Management
  Future<Result<List<Map<String, dynamic>>>> getMenuCategories({int? restaurantId});
  Future<Result<List<Map<String, dynamic>>>> getMenuItems({
    int? categoryId,
    int? restaurantId,
  });
  Future<Result<Map<String, dynamic>>> getMenuCategoryDetails(
    int id, {
    int? restaurantId,
  });
  Future<Result<Map<String, dynamic>>> createMenuCategory(Map<String, dynamic> data);
  Future<Result<Map<String, dynamic>>> updateMenuCategory(int id, Map<String, dynamic> data);
  Future<Result<void>> deleteMenuCategory(int id);
  Future<Result<Map<String, dynamic>>> createMenuItem(Map<String, dynamic> data);
  Future<Result<Map<String, dynamic>>> updateMenuItem(int id, Map<String, dynamic> data);
  Future<Result<void>> deleteMenuItem(int id);

  // Opening Slots
  Future<Result<List<Map<String, dynamic>>>> getOpeningSlots({int? restaurantId});
  Future<Result<Map<String, dynamic>>> createOpeningSlot(Map<String, dynamic> data);

  // Deal Redemption
  Future<Result<Map<String, dynamic>>> redeemDealByQR(
    String qrData, {
    required double price,
    required int peopleCount,
    int? restaurantId,
  });
  Future<Result<Map<String, dynamic>>> redeemDealByCode(
    String redemptionCode, {
    required double price,
    required int peopleCount,
    int? restaurantId,
  });

  // Loyalty Rewards
  Future<Result<Map<String, dynamic>>> claimLoyaltyRewardByQR(String qrData);
  Future<Result<Map<String, dynamic>>> claimLoyaltyRewardByCode(String rewardCode);

  // Loyalty Program Management
  Future<Result<Map<String, dynamic>>> getLoyaltyCustomers({
    required int restaurantId,
    bool? eligibleOnly,
  });
  Future<Result<Map<String, dynamic>>> claimLoyaltyReward({
    required int restaurantId,
    required int userId,
  });
  Future<Result<List<Map<String, dynamic>>>> getLoyaltyHistory({
    required int restaurantId,
    int? userId,
    String? status,
  });

  // Redemption & History
  Future<Result<List<Map<String, dynamic>>>> getMerchantRedemptionHistory({
    int? restaurantId,
    int? limit,
  });

  // Reviews
  Future<Result<List<Map<String, dynamic>>>> getMerchantReviews({int? restaurantId});

  // Bookings (from BookingService wrapped for merchant context)
  Future<Result<List<Map<String, dynamic>>>> getMerchantBookings({
    int? restaurantId,
    String? status,
    String? startDate,
    String? endDate,
  });
  Future<Result<Map<String, dynamic>?>> getMerchantBooking(int bookingId);
  Future<Result<Map<String, dynamic>>> reviewBooking(int bookingId, String status);
  Future<Result<Map<String, dynamic>>> markBookingArrived(int bookingId, String arrivalTime);
  Future<Result<Map<String, dynamic>>> markBookingNoShow(
    int bookingId,
    String reason,
    String notes,
  );
  Future<Result<List<Map<String, dynamic>>>> getUpcomingReminders();

  // Reference Data (cities, categories, facilities, cuisines)
  Future<Result<List<Map<String, dynamic>>>> getCities({
    int? countryId,
    bool? isActive,
    String? search,
    String? ordering,
  });
  Future<Result<List<Map<String, dynamic>>>> getCategories({
    String? search,
    String? ordering,
  });
  Future<Result<List<Map<String, dynamic>>>> getFacilities({
    String? search,
    String? ordering,
  });
  Future<Result<List<Map<String, dynamic>>>> getCuisines({
    String? search,
    String? ordering,
  });
}
