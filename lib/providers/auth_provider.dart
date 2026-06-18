import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/firebase_messaging_service.dart';
import '../models/api_user.dart';

/// Authentication provider for managing auth state (Singleton)
class AuthProvider extends ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;
  AuthProvider._internal() {
    _initializeAuth();
  }

  final AuthService _authService = AuthService();

  final Rxn<ApiUser> _user = Rxn<ApiUser>();
  final RxBool _isLoading = false.obs;
  final RxBool _isAuthenticated = false.obs;
  final RxnString _errorMessage = RxnString();
  final RxString _userRole = 'customer'.obs; // 'customer' or 'merchant'
  final RxBool _isGuestMode = false.obs;

  ApiUser? get user => _user.value;
  bool get isLoading => _isLoading.value;
  bool get isAuthenticated => _isAuthenticated.value;
  String? get errorMessage => _errorMessage.value;
  String get userRole => _userRole.value;
  bool get isGuestMode => _isGuestMode.value;
  bool get isMerchant => _userRole.value == 'merchant';
  bool get isCustomer =>
      _userRole.value == 'customer' || _userRole.value == 'mystery_guest';
  bool get isMysteryGuest => _userRole.value == 'mystery_guest';

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    _isLoading.value = true;
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
          _user.value = user;
          _userRole.value = user.profile?.role ?? (user.isMerchant ? 'merchant' : 'customer');
          _isAuthenticated.value = true;
          debugPrint(
            'DEBUG AuthProvider._initializeAuth: Logged in as user=${user.email}, _userRole=${_userRole.value}',
          );
        } else {
          await _authService.logout();
          _isAuthenticated.value = false;
          _userRole.value = 'customer';
          debugPrint(
            'DEBUG AuthProvider._initializeAuth: login failed after fallback attempts, logging out',
          );
        }
      } else {
        _isAuthenticated.value = false;
        _userRole.value = 'customer';
        debugPrint('DEBUG AuthProvider._initializeAuth: not logged in');
      }
    } catch (e) {
      _errorMessage.value = 'Failed to initialize authentication';
      _isAuthenticated.value = false;
      debugPrint('DEBUG AuthProvider._initializeAuth: ERROR: $e');
    } finally {
      _isLoading.value = false;
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
    _isLoading.value = true;
    _errorMessage.value = null;
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
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Stage 1: Request OTP
  Future<bool> registerInit({
    required String email,
    required String role,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      await _authService.registerInit(email: email, role: role);
      _isLoading.value = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Stage 2: Verify OTP
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      await _authService.verifyOtp(email: email, otp: otp);
      _isLoading.value = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Stage 1.5: Resend OTP
  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    return await _authService.resendOtp(email: email);
  }

  /// Stage 3: Complete registration and create account (with password)
  Future<bool> registerComplete({
    required String email,
    required String otp,
    required String password,
    String? username,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      await _authService.registerComplete(
        email: email,
        otp: otp,
        password: password,
        username: username,
      );

      // After successful registration, login the user
      return await login(email: email, password: password);
    } catch (e) {
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Check username availability
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    return await _authService.checkUsernameAvailability(username);
  }

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      final loginResponse = await _authService.login(
        email: email,
        password: password,
      );

      _user.value = loginResponse.user;
      _userRole.value = loginResponse.role; // Store role from login response
      debugPrint(
        'DEBUG AuthProvider.login: loginResponse.role="${loginResponse.role}", _userRole="${_userRole.value}", isMysteryGuest=$isMysteryGuest',
      );
      _isAuthenticated.value = true;
      _isGuestMode.value = false;
      _isLoading.value = false;
      notifyListeners();

      // Register FCM token with backend after successful login
      try {
        final firebaseService = FirebaseMessagingService();
        await firebaseService.registerTokenAfterLogin();
      } catch (e) {
        debugPrint('DEBUG AuthProvider.login: Error registering FCM token: $e');
      }

      // Refresh user data to get full profile (including email)
      await refreshUser();

      return true;
    } catch (e) {
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated.value = false;
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with Google
  Future<bool> loginWithGoogle() async {
    debugPrint('DEBUG: AuthProvider.loginWithGoogle -> Triggered');
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      final loginResponse = await _authService.loginWithGoogle();

      _user.value = loginResponse.user;
      _userRole.value = loginResponse.role;
      _isAuthenticated.value = true;
      _isLoading.value = false;
      debugPrint(
        'DEBUG: AuthProvider.loginWithGoogle -> Success: authenticated as ${_user.value?.email}',
      );
      notifyListeners();

      // Register FCM token with backend after successful login
      try {
        final firebaseService = FirebaseMessagingService();
        await firebaseService.registerTokenAfterLogin();
      } catch (e) {
        debugPrint('DEBUG AuthProvider.loginWithGoogle: Error registering FCM token: $e');
      }

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
      _errorMessage.value = isUserCancelled ? null : message;
      _isAuthenticated.value = false;
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with Apple
  Future<bool> loginWithApple() async {
    debugPrint('DEBUG: AuthProvider.loginWithApple -> Triggered');
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      final loginResponse = await _authService.loginWithApple();

      _user.value = loginResponse.user;
      _userRole.value = loginResponse.role;
      _isAuthenticated.value = true;
      _isLoading.value = false;
      debugPrint(
        'DEBUG: AuthProvider.loginWithApple -> Success: authenticated as ${_user.value?.email}',
      );
      notifyListeners();

      // Register FCM token with backend after successful login
      try {
        final firebaseService = FirebaseMessagingService();
        await firebaseService.registerTokenAfterLogin();
      } catch (e) {
        debugPrint('DEBUG AuthProvider.loginWithApple: Error registering FCM token: $e');
      }

      // Refresh user data to get full profile (including email)
      await refreshUser();

      return true;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      debugPrint('DEBUG: AuthProvider.loginWithApple -> Catching error: $message');

      _errorMessage.value = message.contains('Apple login cancelled') ? null : message;
      _isAuthenticated.value = false;
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading.value = true;
    notifyListeners();

    try {
      // Run FCM deactivation and refresh-token revoke together; then clear storage.
      // Google Sign-In is not awaited in wipe so the UI is not blocked on Play Services.
      await Future.wait<void>([
        FirebaseMessagingService().deactivateCurrentDevice(),
        _authService.postLogoutToServer(),
      ]);
    } catch (e) {
      debugPrint('DEBUG AuthProvider.logout: $e');
    } finally {
      try {
        await _authService.wipeLocalSessionAfterLogout();
      } catch (e) {
        debugPrint('DEBUG AuthProvider.logout: local wipe: $e');
      }
      _user.value = null;
      _isAuthenticated.value = false;
      _isGuestMode.value = false;
      _userRole.value = 'customer';
      _errorMessage.value = null;
      _isLoading.value = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = null;
    notifyListeners();
  }

  /// Skip login and enter guest mode
  void skipLogin() {
    _isGuestMode.value = true;
    _isAuthenticated.value = false;
    _user.value = null;
    _userRole.value = 'customer';
    notifyListeners();
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _user.value = user;
        notifyListeners();
      } else {
        // If getting user from network failed but didn't throw an auth error,
        // we might be offline. Let's see if we have them cached.
        final cachedUser = await _authService.getStoredUser();
        if (cachedUser != null) {
          _user.value = cachedUser;
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

  /// Request password reset OTP
  Future<bool> requestPasswordResetOtp({required String email}) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      await _authService.requestPasswordResetOtp(email: email);
      _isLoading.value = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify password reset OTP
  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      await _authService.verifyPasswordResetOtp(email: email, otp: otp);
      _isLoading.value = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Confirm password reset with OTP
  Future<bool> confirmPasswordReset({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      await _authService.confirmPasswordReset(
        email: email,
        otp: otp,
        password: password,
        confirmPassword: confirmPassword,
      );
      _isLoading.value = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Request forgot password email
  Future<bool> forgotPassword({required String email}) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      await _authService.passwordReset(email: email);
      _isLoading.value = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Update current user profile
  Future<bool> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    File? imageFile,
    String? avatarUrl,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      final updatedUser = await _authService.updateProfile(
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        imageFile: imageFile,
        avatarUrl: avatarUrl,
      );
      
      // Update local state with the returned user, 
      // but if the backend hasn't implemented avatarUrl yet, 
      // ensure we keep the local selection.
      _user.value = updatedUser;
      if (avatarUrl != null && _user.value != null) {
        _user.value = _user.value!.copyWith(
          profile: _user.value!.profile?.copyWith(profilePicture: avatarUrl) ?? 
                  UserProfile(role: _userRole.value, profilePicture: avatarUrl),
        );
      }
      
      _isLoading.value = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Stage 1: Initialize account deletion (Request OTP)
  Future<bool> deleteAccountInit() async {
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      await _authService.initDeleteAccount();
      _isLoading.value = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }

  /// Stage 2: Delete current user account (Verify OTP and Delete)
  Future<bool> deleteAccount({required String otp}) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    notifyListeners();

    try {
      await _authService.deleteAccount(otp: otp);
      _user.value = null;
      _isAuthenticated.value = false;
      _userRole.value = 'customer';
      _isLoading.value = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _isLoading.value = false;
      notifyListeners();
      return false;
    }
  }
}
