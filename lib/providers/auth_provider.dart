import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/api_user.dart';

/// Authentication provider for managing auth state (Singleton)
class AuthProvider extends ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;
  AuthProvider._internal() {
    _initializeAuth();
  }

  final AuthService _authService = AuthService();

  ApiUser? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  String _userRole = 'customer'; // 'customer' or 'merchant'

  ApiUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  String get userRole => _userRole;
  bool get isMerchant => _userRole == 'merchant';
  bool get isCustomer => _userRole == 'customer';

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.initializeAuth();
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          _user = user;
          // Determine role from user profile or default to customer
          _userRole =
              user.profile?.role ?? (user.isMerchant ? 'merchant' : 'customer');
          _isAuthenticated = true;
        } else {
          // Token might be invalid, clear auth
          await _authService.logout();
          _isAuthenticated = false;
          _userRole = 'customer';
        }
      } else {
        _isAuthenticated = false;
        _userRole = 'customer';
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize authentication';
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(
        email: email,
        username: username,
        password: password,
        role: role,
      );

      // After successful registration, login the user
      return await login(email: email, password: password);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginResponse = await _authService.login(
        email: email,
        password: password,
      );

      _user = loginResponse.user;
      _userRole = loginResponse.role; // Store role from login response
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with Google
  Future<bool> loginWithGoogle() async {
    print('DEBUG: AuthProvider.loginWithGoogle -> Triggered');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginResponse = await _authService.loginWithGoogle();

      _user = loginResponse.user;
      _userRole = loginResponse.role;
      _isAuthenticated = true;
      _isLoading = false;
      print(
        'DEBUG: AuthProvider.loginWithGoogle -> Success: authenticated as ${_user?.email}',
      );
      notifyListeners();
      return true;
    } catch (e) {
      print('DEBUG: AuthProvider.loginWithGoogle -> Catching error: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _isAuthenticated = false;
      _userRole = 'customer';
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to logout';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _user = user;
        notifyListeners();
      }
    } catch (e) {
      // If we can't get user, they might not be authenticated
      await logout();
    }
  }
}
