import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = true;
  bool _isInitializing = true;
  bool _isVerifyingInternet = false;

  ConnectivityProvider() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityUpdate,
      onError: (_) => _setConnected(false),
    );
    initConnectivity();
  }

  bool get isConnected => _isConnected;
  bool get isInitializing => _isInitializing;

  Future<void> initConnectivity() async {
    _isInitializing = true;
    notifyListeners();

    try {
      final result = await _connectivity.checkConnectivity();
      await _handleConnectivityUpdate(result);
    } catch (_) {
      _setConnected(false);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _handleConnectivityUpdate(List<ConnectivityResult> result) async {
    if (!_hasNetworkInterface(result)) {
      _setConnected(false);
      return;
    }

    await _verifyInternetAccess();
  }

  bool _hasNetworkInterface(List<ConnectivityResult> result) {
    if (result.isEmpty) return false;
    return result.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _verifyInternetAccess() async {
    if (_isVerifyingInternet) return;
    _isVerifyingInternet = true;
    try {
      _setConnected(await _hasRealInternetConnection());
    } finally {
      _isVerifyingInternet = false;
    }
  }

  Future<bool> _hasRealInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one').timeout(
        const Duration(seconds: 3),
      );
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _setConnected(bool value) {
    if (_isConnected == value) return;
    _isConnected = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
