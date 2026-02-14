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
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
  // You can process the notification here if needed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Lock app to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize auth service to load stored tokens
  await AuthService().initializeAuth();

  // Initialize Firebase Messaging Service (which uses NotificationService)
  final firebaseService = FirebaseMessagingService();
  await firebaseService.initialize();

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
            '/home': (context) => MainNavigation(themeProvider: _themeProvider),
          },
        );
      },
    );
  }
}
