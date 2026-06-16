import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/environment.dart';
import '../design/app_colors.dart';
import '../design/app_typography.dart';
import '../routes/app_routes.dart';
import '../services/app_version_checker.dart';

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
    // Start timing the splash screen
    final splashStartTime = DateTime.now();

    // Start checking for updates in background with a timeout
    final Future<bool> versionCheckFuture =
        _checkAppVersion().timeout(const Duration(seconds: 5), onTimeout: () {
      debugPrint('APP_VERSION_CHECK: Timed out after 5 seconds');
      return false; // Don't block on timeout
    });

    // Let the animations run for at least some time
    await Future.delayed(const Duration(milliseconds: 1200));

    // Wait for version check if it's not done yet
    final bool isUpdateBlocking = await versionCheckFuture;

    // If update check returned true (it means we should NOT proceed)
    if (isUpdateBlocking) return;

    // Calculate how much more time we need to stay on splash
    final elapsed = DateTime.now().difference(splashStartTime);
    const minimumSplashDuration = Duration(milliseconds: 2500);

    if (elapsed < minimumSplashDuration) {
      await Future.delayed(minimumSplashDuration - elapsed);
    }

    // Proceed if still mounted
    if (mounted) {
      Get.offNamed(AppRoutes.onboardingCheck);
      // Show optional update sheet after navigation completes
      Future.delayed(const Duration(milliseconds: 500), () {
        AppVersionChecker.showOptionalUpdateSheetOnce();
      });
    }
  }

  /// Returns true if navigation should be blocked (force update page shown).
  Future<bool> _checkAppVersion() async {
    if (!mounted) return false;
    return AppVersionChecker.checkAtStartup();
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.background,
            ],
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                bottom: -90,
                right: -90,
                child: _GlowCircle(
                  size: 260,
                  color: AppColors.secondary.withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                bottom: 120,
                left: -60,
                child: _GlowCircle(
                  size: 180,
                  color: AppColors.primary.withValues(alpha: 0.08),
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
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(34),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 14),
                                    ),
                                    BoxShadow(
                                      color: AppColors.secondary.withValues(
                                        alpha: 0.16,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: AppColors.textPrimary.withValues(alpha: 0.06),
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
                                style: AppTypography.headline,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Your discount companion",
                                style: AppTypography.subtitle,
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
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.textPrimary.withValues(alpha: 0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textPrimary.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Loading deals...",
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
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
                      style: AppTypography.caption,
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
