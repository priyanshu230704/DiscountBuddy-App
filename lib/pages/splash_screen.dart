import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/environment.dart';
import '../providers/theme_provider.dart';

/// Splash screen - NeoTaste style
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding-check');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: NeoTasteColors.accent,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: NeoTasteColors.accent.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_dining,
                size: 60,
                color: NeoTasteColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            // App Name
            Text(
              Environment.appName,
              style: GoogleFonts.inter(
                color: NeoTasteColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'Your discount companion',
              style: GoogleFonts.inter(
                color: NeoTasteColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(NeoTasteColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
