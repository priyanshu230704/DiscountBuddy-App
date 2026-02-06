import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/environment.dart';
import 'pages/main_navigation.dart';
import 'pages/auth/login_page.dart';
import 'pages/splash_screen.dart';
import 'pages/onboarding_check_screen.dart';
import 'theme/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize auth service to load stored tokens
  await AuthService().initializeAuth();
  MapboxOptions.setAccessToken(
    "pk.eyJ1Ijoia2V0YW5jaGF2ZGEyMSIsImEiOiJjbWwzbzhkZzIwM3dkM2Vxc2FxNmhvNjduIn0.ujNsfSEeeW3Ad862r3PGQQ",
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const DiscountBuddyApp(),
    ),
  );
}

class DiscountBuddyApp extends StatelessWidget {
  const DiscountBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: Environment.appName,
          debugShowCheckedModeBanner: Environment.enableDebugMode,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const SplashScreen(),
          routes: {
            '/onboarding-check': (context) => const OnboardingCheckScreen(),
            '/login': (context) => const LoginPage(),
            '/home': (context) => const MainNavigation(),
          },
        );
      },
    );
  }
}
