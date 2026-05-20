import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/environment.dart';
import '../design/app_colors.dart';
import '../design/app_typography.dart';
import '../models/app_version_info.dart';
import '../services/app_version_checker.dart';
import '../widgets/app_gradient_button.dart';

/// Full-screen update screen shown instead of a dialog (splash, login, home, etc.).
class AppUpdatePage extends StatefulWidget {
  final AppVersionInfo versionInfo;

  /// Route to open after optional update is dismissed (e.g. `/onboarding-check`).
  final String? continueRoute;

  const AppUpdatePage({
    super.key,
    required this.versionInfo,
    this.continueRoute,
  });

  bool get isForceUpdate =>
      versionInfo.isForceUpdate || versionInfo.isCriticalUpdate;

  @override
  State<AppUpdatePage> createState() => _AppUpdatePageState();
}

class _AppUpdatePageState extends State<AppUpdatePage> {
  String? _currentVersion;
  bool _isLaunchingStore = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _currentVersion = info.version);
  }

  Future<void> _openStore() async {
    final url = widget.versionInfo.storeUrl;
    if (url == null || url.isEmpty) return;

    setState(() => _isLaunchingStore = true);
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) setState(() => _isLaunchingStore = false);
    }
  }

  void _onMaybeLater() {
    AppVersionChecker.resetShowingFlag();
    final route = widget.continueRoute;
    if (route != null) {
      Navigator.of(context).pushReplacementNamed(route);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForce = widget.isForceUpdate;

    return PopScope(
      canPop: !isForce,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    Lottie.asset(
                      'assets/animation/update.json',
                      width: 280,
                      height: 280,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                    const SizedBox(height: 36),
                    Text(
                      isForce ? 'Update Required' : 'Update Available',
                      style: AppTypography.headline.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDarkest,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.versionInfo.updateMessage ??
                          'A new version of ${Environment.appName} is available. '
                              'Please update for the best experience and latest features.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    _buildVersionCard(isForce),
                    const Spacer(flex: 3),
                    AppGradientButton(
                      onPressed:
                          _isLaunchingStore ? null : _openStore,
                      isLoading: _isLaunchingStore,
                      width: double.infinity,
                      child: const Text(
                        'Update Now',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    if (!isForce) ...[
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _onMaybeLater,
                        child: Text(
                          'Maybe Later',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionCard(bool isForce) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _versionRow(
            'Your version',
            _currentVersion ?? '…',
            AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),
          _versionRow(
            'Latest version',
            widget.versionInfo.latestVersion ?? 'Unknown',
            AppColors.primary,
          ),
          if (widget.versionInfo.minimumVersion != null) ...[
            const SizedBox(height: 10),
            _versionRow(
              'Minimum required',
              widget.versionInfo.minimumVersion!,
              isForce ? AppColors.error : AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _versionRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
