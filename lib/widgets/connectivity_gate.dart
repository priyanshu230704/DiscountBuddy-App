import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discount_buddy/core/network/connectivity_provider.dart';
import 'package:discount_buddy/widgets/no_internet_view.dart';

/// Shows [NoInternetView] when offline; otherwise shows [child].
class ConnectivityGate extends StatelessWidget {
  final Widget child;
  final Color? offlineBackgroundColor;
  final VoidCallback? onRetry;
  final bool enabled;

  const ConnectivityGate({
    super.key,
    required this.child,
    this.offlineBackgroundColor,
    this.onRetry,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Selector<ConnectivityProvider, bool>(
      selector: (_, p) => p.isConnected,
      builder: (context, isConnected, _) {
        final isInitializing =
            Provider.of<ConnectivityProvider>(context).isInitializing;

        if (!isConnected && !isInitializing) {
          return NoInternetView(
            backgroundColor: offlineBackgroundColor,
            onRetry: onRetry,
          );
        }
        return child;
      },
    );
  }
}
