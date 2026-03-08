import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/api_user.dart';
import '../config/api_endpoints.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:google_sign_in/google_sign_in.dart';

/// Authentication service for handling user authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  /// Register a new user
  Future<RegisterResponse> register({
    required String email,
    required String username,
    required String password,
    required String role, // 'customer' or 'merchant'
  }) async {
    try {
      final apiType = role == 'merchant' ? ApiType.merchant : ApiType.user;
      final response = await _apiService.post(
        ApiEndpoints.register,
        body: {
          'email': email,
          'username': username,
          'password': password,
          'role': role,
        },
        type: apiType,
      );

      return RegisterResponse.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        // Extract error messages from API response
        String errorMessage = 'Registration failed';
        if (e.data != null) {
          final data = e.data as Map<String, dynamic>;
          if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          } else {
            // Handle field-specific errors
            final errors = <String>[];
            data.forEach((key, value) {
              if (value is List) {
                errors.addAll(value.map((e) => e.toString()));
              } else {
                errors.add(value.toString());
              }
            });
            if (errors.isNotEmpty) {
              errorMessage = errors.join(', ');
            }
          }
        }
        throw ApiException(
          errorMessage,
          statusCode: e.statusCode,
          data: e.data,
        );
      }
      rethrow;
    }
  }

  /// Stage 1: Request OTP
  Future<void> registerInit({
    required String email,
    required String role,
  }) async {
    try {
      await _apiService.post(
        ApiEndpoints.registerInit,
        body: {'email': email, 'role': role},
        type: ApiType.user, // Using user API for registration init as per doc
      );
    } catch (e) {
      if (e is ApiException) {
        String errorMessage = 'OTP Request failed';
        if (e.data != null) {
          final data = e.data as Map<String, dynamic>;
          if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          }
        }
        throw ApiException(
          errorMessage,
          statusCode: e.statusCode,
          data: e.data,
        );
      }
      rethrow;
    }
  }

  /// Stage 2: Verify OTP and create account
  Future<RegisterResponse> registerComplete({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.registerComplete,
        body: {'email': email, 'otp': otp, 'password': password},
        type: ApiType.user,
      );

      return RegisterResponse.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        String errorMessage = 'Registration failed';
        if (e.data != null) {
          final data = e.data as Map<String, dynamic>;
          if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          }
        }
        throw ApiException(
          errorMessage,
          statusCode: e.statusCode,
          data: e.data,
        );
      }
      rethrow;
    }
  }

  /// Login with email and password
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      // Note: We'll attempt login as user by default, but we should ideally know the role
      // For now, let's try to detect if it's a merchant based on previous context or just try user
      final response = await _apiService.post(
        ApiEndpoints.login,
        body: {'email': email, 'password': password},
        type:
            ApiType.user, // Default to user, but we might need a way to switch
      );

      final loginResponse = LoginResponse.fromJson(response);

      // Store tokens and user data
      if (loginResponse.accessToken.isNotEmpty) {
        await _storage.write(
          key: _accessTokenKey,
          value: loginResponse.accessToken,
        );
      }
      if (loginResponse.refreshToken.isNotEmpty) {
        await _storage.write(
          key: _refreshTokenKey,
          value: loginResponse.refreshToken,
        );
      }
      if (loginResponse.user != null) {
        await _storage.write(
          key: _userKey,
          value: jsonEncode(loginResponse.user!.toJson()),
        );
      }

      // Set auth token in API service
      _apiService.setAuthToken(loginResponse.accessToken);

      return loginResponse;
    } catch (e) {
      if (e is ApiException) {
        String errorMessage = 'Login failed';
        if (e.data != null) {
          final data = e.data as Map<String, dynamic>;
          if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          }
        }
        throw ApiException(
          errorMessage,
          statusCode: e.statusCode,
          data: e.data,
        );
      }
      rethrow;
    }
  }

  /// Login with Google
  Future<LoginResponse> loginWithGoogle() async {
    debugPrint('DEBUG: googleLogin -> START');
    try {
      if (!_isGoogleSignInInitialized) {
        await _googleSignIn.initialize(
          serverClientId:
              '690749586825-03r2nfmstuk9cgsuh9gmmhd9c2dpp11q.apps.googleusercontent.com',
        );
        _isGoogleSignInInitialized = true;
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiException('Failed to get Google ID token');
      }

      final response = await _apiService.post(
        ApiEndpoints.googleLogin,
        body: {'id_token': idToken},
      );

      final loginResponse = LoginResponse.fromJson(response);

      if (loginResponse.accessToken.isNotEmpty) {
        await _storage.write(
          key: _accessTokenKey,
          value: loginResponse.accessToken,
        );
      }

      if (loginResponse.refreshToken.isNotEmpty) {
        await _storage.write(
          key: _refreshTokenKey,
          value: loginResponse.refreshToken,
        );
      }

      if (loginResponse.user != null) {
        await _storage.write(
          key: _userKey,
          value: jsonEncode(loginResponse.user!.toJson()),
        );
      }

      _apiService.setAuthToken(loginResponse.accessToken);
      debugPrint('DEBUG: googleLogin -> SUCCESS');
      return loginResponse;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw ApiException('Google login cancelled');
      }
      throw ApiException('Google Sign In failed: ${e.description ?? e.code.name}');
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    // Remove tokens from storage
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);

    // Remove auth token from API service
    _apiService.removeAuthToken();

    // Sign out from Google
    await _googleSignIn.signOut();
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get stored user data
  Future<ApiUser?> getStoredUser() async {
    try {
      final userData = await _storage.read(key: _userKey);
      if (userData != null) {
        final decoded = jsonDecode(userData);
        if (decoded is Map<String, dynamic>) {
          return ApiUser.fromJson(decoded);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Initialize auth (load stored token and set it in API service)
  Future<void> initializeAuth() async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      _apiService.setAuthToken(token);
    }
  }

  /// Refresh access token
  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final response = await _apiService.post(
        ApiEndpoints.refreshToken,
        body: {'refresh': refreshToken},
      );

      final newAccessToken = response['access'] as String;
      await _storage.write(key: _accessTokenKey, value: newAccessToken);
      _apiService.setAuthToken(newAccessToken);

      return newAccessToken;
    } catch (e) {
      // If refresh fails, logout user
      await logout();
      return null;
    }
  }

  /// Get current user from API
  Future<ApiUser?> getCurrentUser() async {
    try {
      final response = await _apiService.get(ApiEndpoints.currentUser);
      return ApiUser.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Request password reset
  Future<void> passwordReset({required String email}) async {
    try {
      await _apiService.post(
        ApiEndpoints.passwordReset,
        body: {'email': email},
      );
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.message, statusCode: e.statusCode, data: e.data);
      }
      rethrow;
    }
  }

  /// Update user profile
  Future<ApiUser> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null || lastName != null) {
        // App uses space-separated names in username
        final currentUsername = (await getStoredUser())?.username ?? '';
        final parts = currentUsername.split(' ');
        final fName = firstName ?? (parts.isNotEmpty ? parts[0] : '');
        final lName =
            lastName ?? (parts.length > 1 ? parts.sublist(1).join(' ') : '');
        body['username'] = '$fName $lName'.trim();
      }
      if (email != null) {
        body['email'] = email;
      }

      final response = await _apiService.patch(
        ApiEndpoints.currentUser,
        body: body,
      );
      return ApiUser.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.message, statusCode: e.statusCode, data: e.data);
      }
      rethrow;
    }
  }
}
