import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discount_buddy/core/network/connectivity_provider.dart';

class NetworkService {
  // Show network status snackbar
  static void showNetworkSnackBar(
    BuildContext context, {
    String? customMessage,
  }) {
    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    if (!connectivityProvider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            customMessage ?? 'No internet connection detected',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Generic refresh handler
  static Future<void> handleRefresh(
    BuildContext context,
    Future<void> Function() refreshFunction, {
    String? noConnectionMessage,
  }) async {
    showNetworkSnackBar(context, customMessage: noConnectionMessage);
    await refreshFunction();
  }
}
