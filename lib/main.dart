import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/environment.dart';
import 'services/app_version_checker.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'services/auth_service.dart';
import 'services/firebase_messaging_service.dart'; // Import the service
import 'services/app_permission_service.dart';
import 'firebase_options.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:discount_buddy/utils/date_time_utils.dart';
import 'package:get/get.dart';
import 'routes/app_routes.dart';
import 'routes/app_pages.dart';
import 'routes/bindings/initial_binding.dart';
import 'utils/navigator_key.dart';
import 'package:provider/provider.dart';

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
  // intl: DateFormat(…, 'en_US') in [DateTimeUtils] requires this before first use
  final List<Future<dynamic>> initializations = [
    dotenv.load(fileName: ".env"),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    initializeDateFormatting('en_US'),
    Future<void>.sync(DateTimeUtils.ensureTimeZonesInitialized),
  ];

  try {
    debugPrint('🚀 Starting initializations...');
    await Future.wait(initializations);
    debugPrint('✅ Essential services initialized');
  } catch (e) {
    debugPrint('⚠️ Initial initialization error: $e');
  }

  // Must be set before any MapWidget is created. Doing this after permission
  // dialogs races the Nearby tab and leaves the map stuck on the spinner.
  MapboxOptions.setAccessToken(Environment.mapboxAccessToken);

  // Set up background message handler immediate0ly if Firebase is initialized
  if (Firebase.apps.isNotEmpty) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Opt in to edge-to-edge for Android compatibility across SDK levels.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
  final permissionService = AppPermissionService();

  // Initialize auth service to load stored tokens
  await AuthService().initializeAuth();

  try {
    if (Firebase.apps.isNotEmpty) {
      final firebaseService = FirebaseMessagingService();
      await firebaseService.initialize();
    }
  } catch (e) {
    debugPrint('❌ Error initializing Firebase Messaging: $e');
  } finally {
    await permissionService.requestLocationAfterNotifications();
  }
}

class DiscountBuddyApp extends StatefulWidget {
  const DiscountBuddyApp({super.key});

  @override
  State<DiscountBuddyApp> createState() => _DiscountBuddyAppState();
}

class _DiscountBuddyAppState extends State<DiscountBuddyApp>
    with WidgetsBindingObserver {
  final ThemeProvider _themeProvider = ThemeProvider();
  final AuthProvider _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authProvider.addListener(_authStateChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authProvider.removeListener(_authStateChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppVersionChecker.checkOnResume(
          continueRoute: _authProvider.isAuthenticated
              ? AppRoutes.home
              : AppRoutes.login,
        );
      });
    }
  }

  void _authStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConnectivityProvider>(
      create: (_) => ConnectivityProvider(),
      child: ListenableBuilder(
        listenable: _themeProvider,
        builder: (context, child) {
          return GetMaterialApp(
            navigatorKey: navigatorKey,
            title: Environment.appName,
            debugShowCheckedModeBanner: Environment.enableDebugMode,
            theme: _themeProvider.lightTheme,
            darkTheme: _themeProvider.darkTheme,
            themeMode: _themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            initialRoute: AppPages.initial,
            getPages: AppPages.routes,
            initialBinding: InitialBinding(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
