import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/claim_loyalty_reward_by_code_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/claim_loyalty_reward_by_qr_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/claim_loyalty_reward_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/create_deal_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/create_menu_category_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/create_menu_item_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/create_opening_slot_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/create_restaurant_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/delete_deal_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/delete_menu_category_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/delete_menu_item_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/delete_restaurant_image_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/delete_restaurant_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_categories_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_cities_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_cuisines_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_deal_details_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_facilities_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_loyalty_customers_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_loyalty_history_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_menu_categories_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_menu_category_details_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_menu_items_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_merchant_analytics_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_merchant_booking_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_merchant_bookings_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_merchant_dashboard_stats_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_merchant_deals_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_merchant_redemption_history_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_merchant_restaurants_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_merchant_reviews_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_opening_slots_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_restaurant_detail_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/get_upcoming_reminders_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/mark_booking_arrived_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/mark_booking_no_show_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/redeem_deal_by_code_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/redeem_deal_by_qr_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/review_booking_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/set_primary_image_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/toggle_deal_status_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/update_deal_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/update_menu_category_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/update_menu_item_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/update_occupancy_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/update_restaurant_usecase.dart';
import 'package:discount_buddy/features/merchant/domain/usecases/upload_restaurant_image_usecase.dart';
import 'package:discount_buddy/features/merchant/data/merchant_repository_impl.dart';

/// Central provider orchestrating all merchant use cases
class MerchantProvider {
  MerchantProvider({MerchantRepository? repository})
      : _repository = repository ?? MerchantRepositoryImpl();

  final MerchantRepository _repository;

  // Dashboard
  late final GetMerchantDashboardStatsUseCase getMerchantDashboardStats =
      GetMerchantDashboardStatsUseCase(_repository);
  late final GetMerchantAnalyticsUseCase getMerchantAnalytics =
      GetMerchantAnalyticsUseCase(_repository);

  // Restaurants
  late final GetMerchantRestaurantsUseCase getMerchantRestaurants =
      GetMerchantRestaurantsUseCase(_repository);
  late final GetRestaurantDetailUseCase getRestaurantDetail =
      GetRestaurantDetailUseCase(_repository);
  late final CreateRestaurantUseCase createRestaurant =
      CreateRestaurantUseCase(_repository);
  late final UpdateRestaurantUseCase updateRestaurant =
      UpdateRestaurantUseCase(_repository);
  late final DeleteRestaurantUseCase deleteRestaurant =
      DeleteRestaurantUseCase(_repository);
  late final UpdateOccupancyUseCase updateOccupancy =
      UpdateOccupancyUseCase(_repository);

  // Restaurant Images
  late final UploadRestaurantImageUseCase uploadRestaurantImage =
      UploadRestaurantImageUseCase(_repository);
  late final DeleteRestaurantImageUseCase deleteRestaurantImage =
      DeleteRestaurantImageUseCase(_repository);
  late final SetPrimaryImageUseCase setPrimaryImage =
      SetPrimaryImageUseCase(_repository);

  // Deals
  late final GetMerchantDealsUseCase getMerchantDeals =
      GetMerchantDealsUseCase(_repository);
  late final GetDealDetailsUseCase getDealDetails = GetDealDetailsUseCase(_repository);
  late final CreateDealUseCase createDeal = CreateDealUseCase(_repository);
  late final UpdateDealUseCase updateDeal = UpdateDealUseCase(_repository);
  late final DeleteDealUseCase deleteDeal = DeleteDealUseCase(_repository);
  late final ToggleDealStatusUseCase toggleDealStatus =
      ToggleDealStatusUseCase(_repository);

  // Menu Categories
  late final GetMenuCategoriesUseCase getMenuCategories =
      GetMenuCategoriesUseCase(_repository);
  late final GetMenuCategoryDetailsUseCase getMenuCategoryDetails =
      GetMenuCategoryDetailsUseCase(_repository);
  late final CreateMenuCategoryUseCase createMenuCategory =
      CreateMenuCategoryUseCase(_repository);
  late final UpdateMenuCategoryUseCase updateMenuCategory =
      UpdateMenuCategoryUseCase(_repository);
  late final DeleteMenuCategoryUseCase deleteMenuCategory =
      DeleteMenuCategoryUseCase(_repository);

  // Menu Items
  late final GetMenuItemsUseCase getMenuItems = GetMenuItemsUseCase(_repository);
  late final CreateMenuItemUseCase createMenuItem = CreateMenuItemUseCase(_repository);
  late final UpdateMenuItemUseCase updateMenuItem = UpdateMenuItemUseCase(_repository);
  late final DeleteMenuItemUseCase deleteMenuItem = DeleteMenuItemUseCase(_repository);

  // Opening Slots
  late final GetOpeningSlotsUseCase getOpeningSlots =
      GetOpeningSlotsUseCase(_repository);
  late final CreateOpeningSlotUseCase createOpeningSlot =
      CreateOpeningSlotUseCase(_repository);

  // Deal Redemption
  late final RedeemDealByQRUseCase redeemDealByQR =
      RedeemDealByQRUseCase(_repository);
  late final RedeemDealByCodeUseCase redeemDealByCode =
      RedeemDealByCodeUseCase(_repository);

  // Loyalty Rewards
  late final ClaimLoyaltyRewardByQRUseCase claimLoyaltyRewardByQR =
      ClaimLoyaltyRewardByQRUseCase(_repository);
  late final ClaimLoyaltyRewardByCodeUseCase claimLoyaltyRewardByCode =
      ClaimLoyaltyRewardByCodeUseCase(_repository);

  // Loyalty Program
  late final GetLoyaltyCustomersUseCase getLoyaltyCustomers =
      GetLoyaltyCustomersUseCase(_repository);
  late final ClaimLoyaltyRewardUseCase claimLoyaltyReward =
      ClaimLoyaltyRewardUseCase(_repository);
  late final GetLoyaltyHistoryUseCase getLoyaltyHistory =
      GetLoyaltyHistoryUseCase(_repository);

  // Redemption History
  late final GetMerchantRedemptionHistoryUseCase getMerchantRedemptionHistory =
      GetMerchantRedemptionHistoryUseCase(_repository);

  // Reviews
  late final GetMerchantReviewsUseCase getMerchantReviews =
      GetMerchantReviewsUseCase(_repository);

  // Bookings
  late final GetMerchantBookingsUseCase getMerchantBookings =
      GetMerchantBookingsUseCase(_repository);
  late final GetMerchantBookingUseCase getMerchantBooking =
      GetMerchantBookingUseCase(_repository);
  late final ReviewBookingUseCase reviewBooking = ReviewBookingUseCase(_repository);
  late final MarkBookingArrivedUseCase markBookingArrived =
      MarkBookingArrivedUseCase(_repository);
  late final MarkBookingNoShowUseCase markBookingNoShow =
      MarkBookingNoShowUseCase(_repository);
  late final GetUpcomingRemindersUseCase getUpcomingReminders =
      GetUpcomingRemindersUseCase(_repository);

  // Reference Data
  late final GetCitiesUseCase getCities = GetCitiesUseCase(_repository);
  late final GetCategoriesUseCase getCategories = GetCategoriesUseCase(_repository);
  late final GetFacilitiesUseCase getFacilities = GetFacilitiesUseCase(_repository);
  late final GetCuisinesUseCase getCuisines = GetCuisinesUseCase(_repository);
}
