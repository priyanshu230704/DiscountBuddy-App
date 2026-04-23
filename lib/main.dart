import 'package:flutter/material.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
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
  
  // Increment unread count in background persistent storage
  try {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt('unread_notification_count') ?? 0;
    await prefs.setInt('unread_notification_count', currentCount + 1);
    debugPrint('🔄 Background unread count incremented in storage');
  } catch (e) {
    debugPrint('Error updating unread count in background: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize essential services in parallel
  final List<Future> initializations = [
    dotenv.load(fileName: ".env"),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ];

  try {
    debugPrint('🚀 Starting initializations...');
    await Future.wait(initializations);
    debugPrint('✅ Essential services initialized');
  } catch (e) {
    debugPrint('⚠️ Initial initialization error: $e');
  }

  // Set up background message handler immediately if Firebase is initialized
  if (Firebase.apps.isNotEmpty) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Lock app to portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Non-blocking initializations
  _runBackgroundInitializations();

  runApp(const DiscountBuddyApp());
}

/// Run non-critical initializations in background to not block app startup
Future<void> _runBackgroundInitializations() async {
  // Initialize auth service to load stored tokens
  await AuthService().initializeAuth();

  // Initialize Firebase Messaging Service if Firebase is initialized
  if (Firebase.apps.isNotEmpty) {
    try {
      final firebaseService = FirebaseMessagingService();
      // We don't await this here to let the app finish starting
      // but we do start it.
      firebaseService.initialize();
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Messaging: $e');
    }
  }

  MapboxOptions.setAccessToken(Environment.mapboxAccessToken);
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
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: child!,
            );
          },
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
