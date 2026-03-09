import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/environment.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import '../services/app_config_service.dart';
import '../widgets/update_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _bounce;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.55, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.70, curve: Curves.easeOutBack),
      ),
    );

    _bounce = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1.00, curve: Curves.elasticOut),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.00, curve: Curves.easeOut),
    );

    _controller.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    // Small delay to let animations start
    await Future.delayed(const Duration(milliseconds: 500));

    // Check for updates
    bool isUpdateBlocking = await _checkAppVersion();

    // If update check returned true (it means we should NOT proceed)
    if (isUpdateBlocking) return;

    // Proceed if still mounted
    if (mounted) {
      await Future.delayed(
        const Duration(milliseconds: 1500),
      ); // Minimum splash time
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding-check');
      }
    }
  }

  /// Returns true if navigation should be blocked (because of force update)
  Future<bool> _checkAppVersion() async {
    try {
      final configService = AppConfigService();
      final versionInfo = await configService.checkVersion();

      if (versionInfo != null && versionInfo.isUpdateAvailable) {
        bool isForce =
            versionInfo.isForceUpdate || versionInfo.isCriticalUpdate;

        if (mounted) {
          // If it's a force update, this dialog will stay until the app is updated/closed
          await showDialog(
            context: context,
            barrierDismissible: !isForce,
            builder: (context) => UpdateDialog(versionInfo: versionInfo),
          );

          // After dialog closes, check if we should still stop
          // (if the user clicked "Maybe Later" on an optional update, we proceed)
          return isForce;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking app version: $e');
      // Continue even if check fails to not brick the app on network issues
      return false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF4FB), Color(0xFFFFF8EE), Color(0xFFF4F7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                left: -80,
                child: _GlowCircle(
                  size: 220,
                  color: AppColors.primaryPurple.withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                bottom: -90,
                right: -90,
                child: _GlowCircle(
                  size: 260,
                  color: AppColors.secondaryPink.withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                bottom: 120,
                left: -60,
                child: _GlowCircle(
                  size: 180,
                  color: AppColors.primaryPurple.withValues(alpha: 0.08),
                ),
              ),

              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(0, _bounce.value),
                          child: Opacity(
                            opacity: _fade.value,
                            child: Transform.scale(
                              scale: _scale.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(34),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPurple.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 14),
                                    ),
                                    BoxShadow(
                                      color: AppColors.secondaryPink.withValues(
                                        alpha: 0.16,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Image.asset(
                                  "assets/png/db_logo.png",
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Opacity(
                          opacity: _textFade.value,
                          child: Column(
                            children: [
                              Text(
                                Environment.appName,
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF111827),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Your discount companion",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 46),

                        Opacity(
                          opacity: _textFade.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryPurple,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Loading deals...",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 22,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Center(
                    child: Text(
                      "Powered by Markitup Group Ltd.",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
