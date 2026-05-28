import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import all application page screens
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

import '../models/app_version_info.dart';
import '../models/user_interactions.dart';
import '../providers/auth_provider.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    // Core Navigation & Startup Flow
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
        return MainNavigation(
          key: ValueKey(authProvider.isMerchant),
        );
      },
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.appUpdate,
      page: () {
        final args = Get.arguments;
        if (args is! AppVersionInfo) {
          return const SplashScreen();
        }
        return AppUpdatePage(
          versionInfo: args,
          continueRoute: AppRoutes.onboardingCheck,
        );
      },
      transition: Transition.downToUp,
    ),

    // Subpages & Feature Pages
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
  ];
}
