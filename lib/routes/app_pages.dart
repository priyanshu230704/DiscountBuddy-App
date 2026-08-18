import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pages/splash_screen.dart';
import '../pages/onboarding_check_screen.dart';
import '../pages/onboarding_screen.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/auth/forgot_password_page.dart';
import '../pages/auth/reset_password_page.dart';
import '../pages/main_navigation.dart';
import '../pages/app_update_page.dart';
import '../pages/profile_page.dart';
import '../pages/edit_profile_page.dart';
import '../pages/search_page.dart';
import '../pages/notifications_page.dart';
import '../pages/savings_history_page.dart';
import '../pages/saved_restaurants_page.dart';
import '../pages/level_progress_page.dart';
import '../pages/my_deals_page.dart';
import '../pages/join_partner_page.dart';
import '../pages/help_support_page.dart';
import '../pages/privacy_policy_page.dart';
import '../pages/restaurant_details_page.dart';
import '../pages/loyalty/loyalty_cards_screen.dart';

// Merchant Pages
import '../pages/merchant/merchant_dashboard_page.dart';
import '../pages/merchant/merchant_restaurants_page.dart';
import '../pages/merchant/merchant_menu_page.dart';
import '../pages/merchant/merchant_deals_page.dart';
import '../pages/merchant/add_deal_page.dart';
import '../pages/merchant/add_restaurant_page.dart';
import '../pages/merchant/merchant_bookings_page.dart';
import '../pages/merchant/merchant_reviews_page.dart';
import '../pages/merchant/merchant_analytics_page.dart';
import '../pages/merchant/merchant_redemption_history_page.dart';
import '../pages/merchant/qr_scanner_page.dart';
import '../pages/merchant/merchant_calendar_page.dart';
import '../pages/merchant/merchant_reminders_page.dart';
import '../pages/merchant/merchant_loyalty_page.dart';

// User Bookings
import '../pages/bookings/bookings_page.dart';
import '../pages/bookings/create_booking_page.dart';

// Superadmin Pages
import '../pages/admin/admin_home_page.dart';
import '../pages/admin/banners/banners_list_page.dart';
import '../pages/admin/banners/banner_form_page.dart';
import '../pages/admin/spin_to_win/spin_campaigns_list_page.dart';
import '../pages/admin/spin_to_win/spin_campaign_detail_page.dart';
import '../pages/admin/spin_to_win/spin_campaign_form_page.dart';
import '../pages/admin/spin_to_win/spin_item_form_page.dart';
import '../pages/admin/spin_to_win/spin_history_page.dart';

// Customer Spin to Win Pages
import '../pages/spin_to_win/spin_wheel_screen.dart';
import '../pages/spin_to_win/my_prizes_screen.dart';

import '../models/app_version_info.dart';
import '../models/user_interactions.dart';
import '../providers/auth_provider.dart';
import 'app_routes.dart';
import 'bindings/home_binding.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.onboardingCheck,
      page: () => const OnboardingCheckScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => ForgotPasswordPage(
        initialEmail: Get.arguments as String?,
      ),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () {
        final Map<String, dynamic> args = Get.arguments ?? {};
        return ResetPasswordPage(
          email: args['email'] ?? '',
          otp: args['otp'] ?? '',
        );
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () {
        final authProvider = Get.find<AuthProvider>();
        final args = Get.arguments;

        var initialIndex = 0;
        double? initialLatitude;
        double? initialLongitude;

        if (args is Map) {
          final index = args['initialIndex'];
          if (index is int) {
            initialIndex = index;
          }
          initialLatitude = args['latitude'] as double?;
          initialLongitude = args['longitude'] as double?;
        } else if (args is int) {
          initialIndex = args;
        }

        return MainNavigation(
          key: ValueKey(authProvider.isMerchant),
          initialIndex: initialIndex,
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
        );
      },
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.appUpdate,
      page: () {
        final args = Get.arguments;
        if (args is Map<String, dynamic>) {
          final versionInfo = args['versionInfo'];
          if (versionInfo is! AppVersionInfo) {
            return const SplashScreen();
          }
          return AppUpdatePage(
            versionInfo: versionInfo,
            continueRoute: args['continueRoute'] as String? ??
                AppRoutes.onboardingCheck,
          );
        }
        if (args is AppVersionInfo) {
          return AppUpdatePage(
            versionInfo: args,
            continueRoute: AppRoutes.onboardingCheck,
          );
        }
        return const SplashScreen();
      },
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfilePage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.savingsHistory,
      page: () => const SavingsHistoryPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.savedRestaurants,
      page: () => const SavedRestaurantsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.loyaltyCards,
      page: () => const LoyaltyCardsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.levelProgress,
      page: () {
        final args = Get.arguments;
        if (args is! ProfileStats) {
          return const SplashScreen();
        }
        return LevelProgressPage(stats: args);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.myDeals,
      page: () => const MyDealsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.joinPartner,
      page: () => const JoinPartnerPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.helpSupport,
      page: () => const HelpSupportPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => const PrivacyPolicyPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.restaurantDetails,
      page: () {
        final Map<String, dynamic> args = Get.arguments ?? {};
        return RestaurantDetailsPage(
          slug: args['slug'] ?? '',
          latitude: args['latitude'],
          longitude: args['longitude'],
        );
      },
      transition: Transition.rightToLeft,
    ),
    // User Bookings
    GetPage(
      name: AppRoutes.bookings,
      page: () => const BookingsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.createBooking,
      page: () {
        final Map<String, dynamic> args = Get.arguments ?? {};
        return CreateBookingPage(
          restaurantId: args['restaurantId'] ?? '',
          restaurantName: args['restaurantName'] ?? '',
        );
      },
      transition: Transition.rightToLeft,
    ),
    // Merchant Routes - Dashboard
    GetPage(
      name: AppRoutes.merchantDashboard,
      page: () => const MerchantDashboardPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.merchantRestaurants,
      page: () {
        final selectMenuMode = Get.arguments as bool?;
        return MerchantRestaurantsPage(
          selectMenuMode: selectMenuMode ?? false,
        );
      },
      transition: Transition.rightToLeft,
    ),
    // Merchant Routes - Menu & Restaurant Management
    GetPage(
      name: AppRoutes.merchantMenu,
      page: () {
        final Map<String, dynamic> args = Get.arguments ?? {};
        final restaurantId = args['restaurantId'];
        return MerchantMenuPage(
          restaurantId: restaurantId is int ? restaurantId : int.tryParse(restaurantId.toString()) ?? 0,
          restaurantName: args['restaurantName'] ?? '',
        );
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.addRestaurant,
      page: () {
        final args = Get.arguments;
        return AddRestaurantPage(restaurant: args as Map<String, dynamic>?);
      },
      transition: Transition.rightToLeft,
    ),
    // Merchant Routes - Deals
    GetPage(
      name: AppRoutes.merchantDeals,
      page: () {
        final Map<String, dynamic> args = Get.arguments ?? {};
        final restaurantId = args['restaurantId'];
        return MerchantDealsPage(
          restaurantId: restaurantId is int ? restaurantId : int.tryParse(restaurantId.toString()),
        );
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.addDeal,
      page: () {
        final args = Get.arguments;
        return AddDealPage(deal: args as Map<String, dynamic>?);
      },
      transition: Transition.rightToLeft,
    ),
    // Merchant Routes - Bookings, Reviews, Analytics
    GetPage(
      name: AppRoutes.merchantBookings,
      page: () {
        final Map<String, dynamic> args = Get.arguments ?? {};
        final restaurantId = args['restaurantId'];
        return MerchantBookingsPage(
          restaurantId: restaurantId is int ? restaurantId : int.tryParse(restaurantId.toString()),
        );
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.merchantReviews,
      page: () {
        final Map<String, dynamic> args = Get.arguments ?? {};
        final restaurantId = args['restaurantId'];
        return MerchantReviewsPage(
          restaurantId: restaurantId is int ? restaurantId : int.tryParse(restaurantId.toString()),
        );
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.merchantAnalytics,
      page: () {
        final Map<String, dynamic> args = Get.arguments ?? {};
        final restaurantId = args['restaurantId'];
        return MerchantAnalyticsPage(
          restaurantId: restaurantId is int ? restaurantId : int.tryParse(restaurantId.toString()),
          restaurantName: args['restaurantName'] ?? '',
        );
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.merchantRedemptionHistory,
      page: () {
        final Map<String, dynamic> args = Get.arguments ?? {};
        final restaurantId = args['restaurantId'];
        return MerchantRedemptionHistoryPage(
          restaurantId: restaurantId is int ? restaurantId : int.tryParse(restaurantId.toString()),
        );
      },
      transition: Transition.rightToLeft,
    ),
    // Merchant Routes - QR Scanner
    GetPage(
      name: AppRoutes.qrScanner,
      page: () {
        final Map<String, dynamic> args = Get.arguments ?? {};
        return QRScannerPage(
          initialRestaurantId: args['initialRestaurantId'],
        );
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.merchantCalendar,
      page: () {
        final Map<String, dynamic> args = Get.arguments ?? {};
        final restaurantId = args['restaurantId'];
        return MerchantCalendarPage(
          restaurantId: restaurantId is int ? restaurantId : int.tryParse(restaurantId.toString()),
        );
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.merchantReminders,
      page: () => const MerchantRemindersPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.merchantLoyalty,
      page: () => const MerchantLoyaltyPage(),
      transition: Transition.rightToLeft,
    ),
    // Superadmin Routes
    GetPage(
      name: AppRoutes.adminHome,
      page: () => const AdminHomePage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.adminBanners,
      page: () => const BannersListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.adminBannerForm,
      page: () => const BannerFormPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.adminSpinCampaigns,
      page: () => const SpinCampaignsListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.adminSpinCampaignDetail,
      page: () => const SpinCampaignDetailPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.adminSpinCampaignForm,
      page: () => const SpinCampaignFormPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.adminSpinItemForm,
      page: () => const SpinItemFormPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.adminSpinHistory,
      page: () => const SpinHistoryPage(),
      transition: Transition.rightToLeft,
    ),
    // Customer Spin to Win Routes
    GetPage(
      name: AppRoutes.spinToWin,
      page: () => const SpinWheelScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.myPrizes,
      page: () => const MyPrizesScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}
