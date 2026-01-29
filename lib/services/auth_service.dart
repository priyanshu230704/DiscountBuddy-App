import '../services/api_service.dart';
import '../models/api_user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:google_sign_in/google_sign_in.dart';

/// Authentication service for handling user authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '1019573233560-fek4q2bgo1i4rssdgm4pme2b80dj1lim.apps.googleusercontent.com',
  );

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
      final response = await _apiService.post(
        '/users/register/',
        body: {
          'email': email,
          'username': username,
          'password': password,
          'role': role,
        },
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

  /// Login with email and password
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '/users/login/',
        body: {'email': email, 'password': password},
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
          value: loginResponse.user!.toJson().toString(),
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
    print('DEBUG: googleLogin -> START');
    try {
      // Step 1: Get Google ID token from Sign-In
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("User cancelled sign-in");
        throw ApiException('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;

      print("ID TOKEN: ${googleAuth.idToken}");
      print("ACCESS TOKEN: ${googleAuth.accessToken}");

      // Validate that we have the ID token
      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        throw ApiException('Failed to get Google ID token');
      }

      print(
        'DEBUG: googleLogin -> ID Token obtained: ${googleAuth.idToken!.substring(0, 20)}...',
      );

      // Step 2: Call backend API with the ID token
      // POST /api/users/google/ with {"id_token": "<token>"}
      print(
        'DEBUG: googleLogin -> Sending ID token to backend: /api/users/google',
      );
      final response = await _apiService.post(
        '/users/google',
        body: {'id_token': googleAuth.idToken},
      );
      print('DEBUG: googleLogin -> Backend response received');

      // Step 3: Handle the API response
      // Expected response: { "access": "...", "refresh": "...", "user": {...}, "username": "...", "role": "...", ... }
      print('DEBUG: googleLogin -> Parsing response data...');
      final loginResponse = LoginResponse.fromJson(response);
      print(
        'DEBUG: googleLogin -> Parse successful. User: ${loginResponse.username}, Role: ${loginResponse.role}',
      );

      // Store access and refresh tokens securely
      print('DEBUG: googleLogin -> Storing tokens in secure storage...');
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
          value: loginResponse.user!.toJson().toString(),
        );
      }
      print('DEBUG: googleLogin -> Tokens stored successfully');

      // Step 4: Set auth token in API service for subsequent authenticated requests
      // All future API calls will include: Authorization: Bearer <access_token>
      print('DEBUG: googleLogin -> Setting auth token in ApiService');
      _apiService.setAuthToken(loginResponse.accessToken);

      print('DEBUG: googleLogin -> SUCCESS');
      return loginResponse;
    } catch (e) {
      print("Google Sign-In Error: $e");
      if (e is ApiException) {
        String errorMessage = 'Google login failed';
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
      // If it's a platform exception from google_sign_in
      if (e.runtimeType.toString() == 'PlatformException') {
        throw ApiException('Google Sign In failed: ${e.toString()}');
      }
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

    // Sign out from Google if signed in
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
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
        // Note: This is a simplified approach. In production, use proper JSON storage
        // For now, we'll fetch user data from API instead
        return null;
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
        '/users/token/refresh/',
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
      final response = await _apiService.get('/users/me/');
      return ApiUser.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
