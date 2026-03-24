import 'package:flutter/foundation.dart';
import 'dart:io';
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
  bool _isGuestMode = false;

  ApiUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  String get userRole => _userRole;
  bool get isGuestMode => _isGuestMode;
  bool get isMerchant => _userRole == 'merchant';
  bool get isCustomer =>
      _userRole == 'customer' || _userRole == 'mystery_guest';
  bool get isMysteryGuest => _userRole == 'mystery_guest';

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.initializeAuth();
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        ApiUser? user;
        try {
          user = await _authService.getCurrentUser();
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
            debugPrint('DEBUG AuthProvider._initializeAuth: explicitly unauthorized.');
          } else {
            debugPrint('DEBUG AuthProvider._initializeAuth: Network or other error getting user: $e');
          }
        }
        
        // If getting user fails via network, try getting from secure storage first
        if (user == null) {
          debugPrint('DEBUG AuthProvider._initializeAuth: Current user via network failed, trying local storage...');
          user = await _authService.getStoredUser();
          
          // If no local user, or we want to double check, try refreshing token
          if (user == null) {
            debugPrint('DEBUG AuthProvider._initializeAuth: No local user, trying refresh token...');
            try {
              final success = await _authService.refreshAccessToken();
              if (success) {
                user = await _authService.getCurrentUser();
              }
            } catch (e) {
              debugPrint('DEBUG AuthProvider._initializeAuth: Error refreshing token: $e');
            }
          }
        }

        if (user != null) {
          _user = user;
          _userRole = user.profile?.role ?? (user.isMerchant ? 'merchant' : 'customer');
          _isAuthenticated = true;
          debugPrint(
            'DEBUG AuthProvider._initializeAuth: Logged in as user=${user.email}, _userRole=$_userRole',
          );
        } else {
          await _authService.logout();
          _isAuthenticated = false;
          _userRole = 'customer';
          debugPrint(
            'DEBUG AuthProvider._initializeAuth: login failed after fallback attempts, logging out',
          );
        }
      } else {
        _isAuthenticated = false;
        _userRole = 'customer';
        debugPrint('DEBUG AuthProvider._initializeAuth: not logged in');
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize authentication';
      _isAuthenticated = false;
      debugPrint('DEBUG AuthProvider._initializeAuth: ERROR: $e');
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

  /// Stage 1: Request OTP
  Future<bool> registerInit({
    required String email,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerInit(email: email, role: role);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Stage 2: Verify OTP
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyOtp(email: email, otp: otp);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Stage 3: Complete registration and create account (with password)
  Future<bool> registerComplete({
    required String email,
    required String otp,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerComplete(
        email: email,
        otp: otp,
        password: password,
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
      debugPrint(
        'DEBUG AuthProvider.login: loginResponse.role="${loginResponse.role}", _userRole="$_userRole", isMysteryGuest=$isMysteryGuest',
      );
      _isAuthenticated = true;
      _isGuestMode = false;
      _isLoading = false;
      notifyListeners();

      // Refresh user data to get full profile (including email)
      await refreshUser();

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
    debugPrint('DEBUG: AuthProvider.loginWithGoogle -> Triggered');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginResponse = await _authService.loginWithGoogle();

      _user = loginResponse.user;
      _userRole = loginResponse.role;
      _isAuthenticated = true;
      _isLoading = false;
      debugPrint(
        'DEBUG: AuthProvider.loginWithGoogle -> Success: authenticated as ${_user?.email}',
      );
      notifyListeners();

      // Refresh user data to get full profile (including email)
      await refreshUser();

      return true;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      final lower = message.toLowerCase();
      final isUserCancelled = lower.contains('googlesigninexceptioncode.canceled') ||
          lower.contains('cancelled') ||
          lower.contains('canceled by the user') ||
          lower.contains('activity is cancelled by the user');

      debugPrint('DEBUG: AuthProvider.loginWithGoogle -> Catching error: $message');
      // Cancel flow should silently stop loading without showing an error snackbar.
      _errorMessage = isUserCancelled ? null : message;
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with Apple
  Future<bool> loginWithApple() async {
    debugPrint('DEBUG: AuthProvider.loginWithApple -> Triggered');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginResponse = await _authService.loginWithApple();

      _user = loginResponse.user;
      _userRole = loginResponse.role;
      _isAuthenticated = true;
      _isLoading = false;
      debugPrint(
        'DEBUG: AuthProvider.loginWithApple -> Success: authenticated as ${_user?.email}',
      );
      notifyListeners();

      // Refresh user data to get full profile (including email)
      await refreshUser();

      return true;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      debugPrint('DEBUG: AuthProvider.loginWithApple -> Catching error: $message');

      _errorMessage = message.contains('Apple login cancelled') ? null : message;
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
    } catch (e) {
      debugPrint('DEBUG AuthProvider.logout: Error during server logout: $e');
      // Silently proceed with local logout even if server-side fails
    } finally {
      _user = null;
      _isAuthenticated = false;
      _isGuestMode = false;
      _userRole = 'customer';
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Skip login and enter guest mode
  void skipLogin() {
    _isGuestMode = true;
    _isAuthenticated = false;
    _user = null;
    _userRole = 'customer';
    notifyListeners();
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _user = user;
        notifyListeners();
      } else {
        // If getting user from network failed but didn't throw an auth error,
        // we might be offline. Let's see if we have them cached.
        final cachedUser = await _authService.getStoredUser();
        if (cachedUser != null) {
          _user = cachedUser;
          notifyListeners();
        }
      }
    } catch (e) {
      // Only logout if it's explicitly an unauthorized error, otherwise keep current session alive
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
        debugPrint('DEBUG AuthProvider.refreshUser: Unauthorized error, logging out... ($e)');
        await logout();
      } else {
        debugPrint('DEBUG AuthProvider.refreshUser: Non-auth error while refreshing user, preserving session ($e)');
      }
    }
  }

  /// Request forgot password email
  Future<bool> forgotPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.passwordReset(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update current user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    File? imageFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        imageFile: imageFile,
      );
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  /// Stage 1: Initialize account deletion (Request OTP)
  Future<bool> deleteAccountInit() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.initDeleteAccount();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Stage 2: Delete current user account (Verify OTP and Delete)
  Future<bool> deleteAccount({required String otp}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.deleteAccount(otp: otp);
      _user = null;
      _isAuthenticated = false;
      _userRole = 'customer';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
