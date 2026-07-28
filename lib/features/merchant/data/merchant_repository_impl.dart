import 'package:discount_buddy/core/domain/error_mapper.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/data/merchant_service.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class MerchantRepositoryImpl implements MerchantRepository {
  MerchantRepositoryImpl({MerchantService? service})
      : _service = service ?? MerchantService();

  final MerchantService _service;

  Failure _mapError(Object e, {String fallback = 'Something went wrong'}) =>
      mapToFailure(e, fallback: fallback);

  @override
  Future<Result<Map<String, dynamic>>> getMerchantDashboardStats({
    int? restaurantId,
  }) async {
    try {
      final result = await _service.getMerchantDashboardStats(restaurantId: restaurantId);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load dashboard stats'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getMerchantAnalytics({
    int? restaurantId,
    int period = 30,
  }) async {
    try {
      final result = await _service.getMerchantAnalytics(
        restaurantId: restaurantId,
        period: period,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load analytics'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getMerchantRestaurants({
    int? page,
    String? search,
    String? ordering,
    int? cityId,
  }) async {
    try {
      final result = await _service.getMerchantRestaurants(
        page: page,
        search: search,
        ordering: ordering,
        cityId: cityId,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load restaurants'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getRestaurantDetail(int restaurantId) async {
    try {
      final result = await _service.getRestaurantDetail(restaurantId);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load restaurant'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createRestaurant(
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _service.createRestaurant(data);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to create restaurant'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> updateRestaurant(
    int restaurantId,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _service.updateRestaurant(restaurantId, data);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to update restaurant'));
    }
  }

  @override
  Future<Result<void>> deleteRestaurant(int restaurantId) async {
    try {
      await _service.deleteRestaurant(restaurantId);
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to delete restaurant'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> updateOccupancy(
    int restaurantId,
    String occupancy,
  ) async {
    try {
      final result = await _service.updateOccupancy(restaurantId, occupancy);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to update occupancy'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> uploadRestaurantImage({
    required int restaurantId,
    required String imagePath,
    required String imageType,
    String? altText,
    bool isPrimary = false,
  }) async {
    try {
      final result = await _service.uploadRestaurantImage(
        restaurantId: restaurantId,
        imagePath: imagePath,
        imageType: imageType,
        altText: altText,
        isPrimary: isPrimary,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to upload image'));
    }
  }

  @override
  Future<Result<void>> deleteRestaurantImage(int imageId) async {
    try {
      await _service.deleteRestaurantImage(imageId);
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to delete image'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> setPrimaryImage(int imageId) async {
    try {
      final result = await _service.setPrimaryImage(imageId);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to set primary image'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getMerchantDeals({
    int? page,
    int? restaurantId,
    String? dealType,
    bool? isFeatured,
    String? search,
    String? ordering,
  }) async {
    try {
      final result = await _service.getMerchantDeals(
        page: page,
        restaurantId: restaurantId,
        dealType: dealType,
        isFeatured: isFeatured,
        search: search,
        ordering: ordering,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load deals'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getDealDetails(int dealId) async {
    try {
      final result = await _service.getDealDetails(dealId);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load deal'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createDeal(Map<String, dynamic> data) async {
    try {
      final result = await _service.createDeal(data);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to create deal'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> updateDeal(
    int dealId,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _service.updateDeal(dealId, data);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to update deal'));
    }
  }

  @override
  Future<Result<void>> deleteDeal(int dealId) async {
    try {
      await _service.deleteDeal(dealId);
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to delete deal'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> toggleDealStatus(
    int dealId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final result = await _service.toggleDealStatus(
        dealId,
        startDate: startDate,
        endDate: endDate,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to toggle deal status'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getMenuCategories({
    int? restaurantId,
  }) async {
    try {
      final result = await _service.getMenuCategories(restaurantId: restaurantId);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load menu categories'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getMenuItems({
    int? categoryId,
    int? restaurantId,
  }) async {
    try {
      final result = await _service.getMenuItems(
        categoryId: categoryId,
        restaurantId: restaurantId,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load menu items'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getMenuCategoryDetails(
    int id, {
    int? restaurantId,
  }) async {
    try {
      final result = await _service.getMenuCategoryDetails(id, restaurantId: restaurantId);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load menu category'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createMenuCategory(
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _service.createMenuCategory(data);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to create menu category'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> updateMenuCategory(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _service.updateMenuCategory(id, data);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to update menu category'));
    }
  }

  @override
  Future<Result<void>> deleteMenuCategory(int id) async {
    try {
      await _service.deleteMenuCategory(id);
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to delete menu category'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createMenuItem(Map<String, dynamic> data) async {
    try {
      final result = await _service.createMenuItem(data);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to create menu item'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> updateMenuItem(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _service.updateMenuItem(id, data);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to update menu item'));
    }
  }

  @override
  Future<Result<void>> deleteMenuItem(int id) async {
    try {
      await _service.deleteMenuItem(id);
      return const Success(null);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to delete menu item'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getOpeningSlots({
    int? restaurantId,
  }) async {
    try {
      final result = await _service.getOpeningSlots(restaurantId: restaurantId);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load opening slots'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createOpeningSlot(
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _service.createOpeningSlot(data);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to create opening slot'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> redeemDealByQR(
    String qrData, {
    required double price,
    required int peopleCount,
    int? restaurantId,
  }) async {
    try {
      final result = await _service.redeemDealByQR(
        qrData,
        price: price,
        peopleCount: peopleCount,
        restaurantId: restaurantId,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Redemption failed'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> redeemDealByCode(
    String redemptionCode, {
    required double price,
    required int peopleCount,
    int? restaurantId,
  }) async {
    try {
      final result = await _service.redeemDealByCode(
        redemptionCode,
        price: price,
        peopleCount: peopleCount,
        restaurantId: restaurantId,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Redemption failed'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> claimLoyaltyRewardByQR(String qrData) async {
    try {
      final result = await _service.claimLoyaltyRewardByQR(qrData);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Loyalty claim failed'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> claimLoyaltyRewardByCode(String rewardCode) async {
    try {
      final result = await _service.claimLoyaltyRewardByCode(rewardCode);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Loyalty claim failed'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getLoyaltyCustomers({
    required int restaurantId,
    bool? eligibleOnly,
  }) async {
    try {
      final result = await _service.getLoyaltyCustomers(
        restaurantId: restaurantId,
        eligibleOnly: eligibleOnly,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load loyalty customers'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> claimLoyaltyReward({
    required int restaurantId,
    required int userId,
  }) async {
    try {
      final result = await _service.claimLoyaltyReward(
        restaurantId: restaurantId,
        userId: userId,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to claim loyalty reward'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getLoyaltyHistory({
    required int restaurantId,
    int? userId,
    String? status,
  }) async {
    try {
      final result = await _service.getLoyaltyHistory(
        restaurantId: restaurantId,
        userId: userId,
        status: status,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load loyalty history'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getMerchantRedemptionHistory({
    int? restaurantId,
    int? limit,
  }) async {
    try {
      final result = await _service.getMerchantRedemptionHistory(
        restaurantId: restaurantId,
        limit: limit,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load redemption history'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getMerchantReviews({
    int? restaurantId,
  }) async {
    try {
      final result = await _service.getMerchantReviews(restaurantId: restaurantId);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load reviews'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getMerchantBookings({
    int? restaurantId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final result = await _service.getMerchantBookings(
        restaurantId: restaurantId,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load bookings'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>?>> getMerchantBooking(int bookingId) async {
    try {
      final result = await _service.getMerchantBooking(bookingId);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load booking'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> reviewBooking(int bookingId, String status) async {
    try {
      final result = await _service.reviewBooking(bookingId, status);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to review booking'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> markBookingArrived(
    int bookingId,
    String arrivalTime,
  ) async {
    try {
      final result = await _service.markBookingArrived(bookingId, arrivalTime);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to mark booking arrived'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> markBookingNoShow(
    int bookingId,
    String reason,
    String notes,
  ) async {
    try {
      final result = await _service.markBookingNoShow(bookingId, reason, notes);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to mark booking no-show'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getUpcomingReminders() async {
    try {
      final result = await _service.getUpcomingReminders();
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load reminders'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getCities({
    int? countryId,
    bool? isActive,
    String? search,
    String? ordering,
  }) async {
    try {
      final result = await _service.getCities(
        countryId: countryId,
        isActive: isActive,
        search: search,
        ordering: ordering,
      );
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load cities'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getCategories({
    String? search,
    String? ordering,
  }) async {
    try {
      final result = await _service.getCategories(search: search, ordering: ordering);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load categories'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getFacilities({
    String? search,
    String? ordering,
  }) async {
    try {
      final result = await _service.getFacilities(search: search, ordering: ordering);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load facilities'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getCuisines({
    String? search,
    String? ordering,
  }) async {
    try {
      final result = await _service.getCuisines(search: search, ordering: ordering);
      return Success(result);
    } catch (e) {
      return Err(_mapError(e, fallback: 'Failed to load cuisines'));
    }
  }
}
