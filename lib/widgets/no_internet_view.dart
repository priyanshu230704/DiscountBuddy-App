import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/core/network/connectivity_provider.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';

class NoInternetView extends StatelessWidget {
  /// When null, uses [AppColors.backgroundGradient] (same as [AppScaffold] / home).
  final Color? backgroundColor;
  final VoidCallback? onRetry;

  const NoInternetView({
    super.key,
    this.backgroundColor,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: backgroundColor == null ? AppColors.backgroundGradient : null,
        color: backgroundColor,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animation/No internet connection - Empty state.json',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDarkest,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Please check your network settings and try again.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppGradientButton(
                onPressed: () async {
                  if (onRetry != null) {
                    onRetry!();
                  } else {
                    await Provider.of<ConnectivityProvider>(context, listen: false)
                        .initConnectivity();
                  }
                },
                width: 160,
                height: 48,
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    fontFamily: 'Inter',
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
