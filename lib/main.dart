import 'package:flutter/material.dart';
import 'config/environment.dart';
import 'pages/main_navigation.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(const DiscountBuddyApp());
}

class DiscountBuddyApp extends StatefulWidget {
  const DiscountBuddyApp({super.key});

  @override
  State<DiscountBuddyApp> createState() => _DiscountBuddyAppState();
}

class _DiscountBuddyAppState extends State<DiscountBuddyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

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
          themeMode: _themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: MainNavigation(themeProvider: _themeProvider),
        );
      },
    );
  }
}
