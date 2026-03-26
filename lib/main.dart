import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/environment.dart';
import 'pages/main_navigation.dart';
import 'pages/auth/login_page.dart';
import 'pages/splash_screen.dart';
import 'pages/onboarding_check_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/firebase_messaging_service.dart'; // Import the service
import 'firebase_options.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'utils/navigator_key.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase in background handler: $e');
  }
  debugPrint('Handling background message: ${message.messageId}');
  // You can process the notification here if needed
}

// Request ATT Permission first for iOS
Future<void> _requestATTPermissionFirst() async {
  if (!Platform.isIOS) return;

  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;

    if (status == TrackingStatus.notDetermined) {
      // 800ms delay to ensure the app is ready for the dialog
      await Future.delayed(const Duration(milliseconds: 800));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  } catch (e) {
    debugPrint('Error requesting ATT permission: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Request ATT Permission (iOS only) before other initializations
  await _requestATTPermissionFirst();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    debugPrint(
      'Please ensure you have added google-services.json (Android) or GoogleService-Info.plist (iOS)',
    );
  }

  // Set up background message handler
  if (Firebase.apps.isNotEmpty) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Lock app to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize auth service to load stored tokens
  await AuthService().initializeAuth();

  // Initialize Firebase Messaging Service if Firebase is initialized
  if (Firebase.apps.isNotEmpty) {
    try {
      final firebaseService = FirebaseMessagingService();
      await firebaseService.initialize();
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Messaging: $e');
    }
  } else {
    debugPrint(
      '⚠️ Skipping Firebase Messaging initialization as Firebase is not initialized',
    );
  }

  MapboxOptions.setAccessToken(Environment.mapboxAccessToken);
  runApp(const DiscountBuddyApp());
}

class DiscountBuddyApp extends StatefulWidget {
  const DiscountBuddyApp({super.key});

  @override
  State<DiscountBuddyApp> createState() => _DiscountBuddyAppState();
}

class _DiscountBuddyAppState extends State<DiscountBuddyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  final AuthProvider _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();
    _authProvider.addListener(_authStateChanged);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_authStateChanged);
    super.dispose();
  }

  void _authStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: Environment.appName,
          debugShowCheckedModeBanner: Environment.enableDebugMode,
          theme: _themeProvider.lightTheme,
          darkTheme: _themeProvider.darkTheme,
          themeMode: _themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const SplashScreen(),
          routes: {
            '/onboarding-check': (context) => const OnboardingCheckScreen(),
            '/login': (context) => const LoginPage(),
            '/home': (context) => MainNavigation(
              key: ValueKey(_authProvider.isMerchant),
            ),
          },
        );
      },
    );
  }
}
