import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:discount_buddy/core/network/api_service.dart';
import 'package:discount_buddy/features/auth/models/api_user.dart';
import 'package:discount_buddy/core/config/api_endpoints.dart';
import 'package:discount_buddy/core/config/environment.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Authentication service for handling user authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _apiService.onUnauthorized = refreshAccessToken;
  }


  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _deviceTokenIdKey = 'device_token_id';

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
        withAuth: false,
      );

      return RegisterResponse.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        // Extract error messages from API response
        String errorMessage = e.data != null ? 'Registration failed' : e.message;
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
        withAuth: false,
      );
    } catch (e) {
      if (e is ApiException) {
        String errorMessage = e.data != null ? 'OTP Request failed' : e.message;
        if (e.data != null) {
          final data = e.data as Map<String, dynamic>;
          if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          } else if (data.containsKey('email')) {
            final emailErrors = data['email'];
            if (emailErrors is List && emailErrors.isNotEmpty) {
              errorMessage = emailErrors.first.toString();
            } else {
              errorMessage = emailErrors.toString();
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

  /// Stage 2: Verify OTP
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _apiService.post(
        ApiEndpoints.verifyOtp,
        body: {'email': email, 'otp': otp},
        type: ApiType.user,
        withAuth: false,
      );
    } catch (e) {
      if (e is ApiException) {
        String errorMessage = e.data != null ? 'OTP verification failed' : e.message;
        if (e.data != null) {
          final data = e.data as Map<String, dynamic>;
          if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          } else {
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

  /// Stage 1.5: Resend OTP
  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.resendOtp,
        body: {'email': email},
        type: ApiType.user,
        withAuth: false,
      );
      // Let's ensure it returns success on 200/OK
      return {'success': true, 'data': response};
    } catch (e) {
      if (e is ApiException) {
        if (e.data != null && e.data is Map<String, dynamic>) {
          final data = e.data as Map<String, dynamic>;
          return {
            'success': false,
            'detail': data['detail'] ?? 'Failed to resend OTP',
            'remaining_minutes': data['remaining_minutes']
          };
        }
        return {'success': false, 'detail': e.message};
      }
      return {'success': false, 'detail': 'Network error. Please try again.'};
    }
  }

  /// Stage 3: Verify OTP and create account
  Future<RegisterResponse> registerComplete({
    required String email,
    required String otp,
    required String password,
    String? username,
  }) async {
    try {
      final body = {'email': email, 'otp': otp, 'password': password};
      if (username != null && username.isNotEmpty) {
        body['username'] = username;
      }
      
      final response = await _apiService.post(
        ApiEndpoints.registerComplete,
        body: body,
        type: ApiType.user,
        withAuth: false,
      );

      return RegisterResponse.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        String errorMessage = e.data != null ? 'Registration failed' : e.message;
        if (e.data != null) {
          final data = e.data as Map<String, dynamic>;
          if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          } else {
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

  /// Check username availability
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.checkUsername}?username=${Uri.encodeQueryComponent(username)}',
        type: ApiType.user,
        withAuth: false,
      );
      return response;
    } catch (e) {
      if (e is ApiException) {
        if (e.data != null && e.data is Map<String, dynamic>) {
          return e.data as Map<String, dynamic>;
        }
        return {'available': false, 'error': e.message};
      }
      return {'available': false, 'error': 'Network error checking username'};
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
        withAuth: false,
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
        String errorMessage = e.data != null ? 'Login failed' : e.message;
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

      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        throw ApiException('Google login cancelled');
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiException('Failed to get Google ID token');
      }

      final response = await _apiService.post(
        ApiEndpoints.oauthLogin,
        body: {
          'provider': 'google',
          'token': idToken,
        },
        withAuth: false,
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
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    }
  }

  /// Login with Apple
  Future<LoginResponse> loginWithApple() async {
    debugPrint('DEBUG: appleLogin -> START');
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String identityToken = credential.identityToken ?? '';

      if (identityToken.isEmpty) {
        throw ApiException('Failed to get Apple identity token');
      }

      final response = await _apiService.post(
        ApiEndpoints.oauthLogin,
        body: {
          'provider': 'apple',
          'token': identityToken,
        },
        withAuth: false,
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
      debugPrint('DEBUG: appleLogin -> SUCCESS');
      return loginResponse;
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        throw ApiException('Apple login cancelled');
      }
      debugPrint("Apple Sign-In Error: $e");
      rethrow;
    }
  }

  /// Blacklist refresh token on the server (call while credentials still exist).
  Future<void> postLogoutToServer() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiService.post(
          ApiEndpoints.logout,
          body: {'refresh': refreshToken},
        );
      }
    } catch (e) {
      if (Environment.enableLogging) {
        debugPrint('Server logout failed, cleaning up local state... Error: $e');
      }
    }
  }

  /// Clear secure storage and in-memory auth. Google sign-out runs in the
  /// background so logout does not wait on Play Services (often 1–2s).
  Future<void> wipeLocalSessionAfterLogout() async {
    await _storage.deleteAll();
    _apiService.removeAuthToken();
    unawaited(
      _googleSignIn.signOut().catchError((Object e) {
        if (Environment.enableLogging) {
          debugPrint('Google signOut: $e');
        }
      }),
    );
  }

  bool _isLoggingOut = false;

  /// Logout user (refresh-token revoke + local wipe). Used when FCM cleanup
  /// is not needed (e.g. token refresh failure).
  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      await postLogoutToServer();
      await wipeLocalSessionAfterLogout();
    } finally {
      _isLoggingOut = false;
    }
  }


  /// Initialize account deletion (Stage 1: Request OTP)
  Future<void> initDeleteAccount() async {
    try {
      await _apiService.post(ApiEndpoints.deleteAccountInit, body: {});
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.message, statusCode: e.statusCode, data: e.data);
      }
      rethrow;
    }
  }

  /// Delete user account (Stage 2: Verify OTP and Delete)
  Future<void> deleteAccount({required String otp}) async {
    try {
      await _apiService.delete(
        ApiEndpoints.deleteAccount,
        body: {'otp': otp},
      );
      await logout();
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.message, statusCode: e.statusCode, data: e.data);
      }
      rethrow;
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
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        // No refresh token available; clear in-memory auth to prevent sending stale Authorization.
        _apiService.removeAuthToken();
        return false;
      }

      final response = await _apiService.post(
        ApiEndpoints.refreshToken,
        body: {'refresh': refreshToken},
        withAuth: false,
      );

      final newAccessToken = response['access'] as String;
      await _storage.write(key: _accessTokenKey, value: newAccessToken);
      _apiService.setAuthToken(newAccessToken);

      return true;
    } catch (e) {
      if (Environment.enableLogging) {
        debugPrint('Refresh access token failed: $e');
      }
      // If refresh fails, it could be the 7-day limit or other issue
      // Logout user to clean up local state
      await logout();
      return false;
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

  /// Request password reset OTP
  Future<void> requestPasswordResetOtp({required String email}) async {
    try {
      await _apiService.post(
        ApiEndpoints.passwordResetRequest,
        body: {'email': email},
        withAuth: false,
      );
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.message, statusCode: e.statusCode, data: e.data);
      }
      rethrow;
    }
  }

  /// Verify password reset OTP
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _apiService.post(
        ApiEndpoints.passwordResetVerify,
        body: {
          'email': email,
          'otp': otp,
        },
        withAuth: false,
      );
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.message, statusCode: e.statusCode, data: e.data);
      }
      rethrow;
    }
  }

  /// Confirm password reset with OTP
  Future<void> confirmPasswordReset({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _apiService.post(
        ApiEndpoints.passwordResetConfirm,
        body: {
          'email': email,
          'otp': otp,
          'password': password,
          'confirm_password': confirmPassword,
        },
        withAuth: false,
      );
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.message, statusCode: e.statusCode, data: e.data);
      }
      rethrow;
    }
  }

  /// Request password reset
  Future<void> passwordReset({required String email}) async {
    try {
      await _apiService.post(
        ApiEndpoints.passwordReset,
        body: {'email': email},
        withAuth: false,
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
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    File? imageFile,
    String? avatarUrl,
  }) async {
    try {
      final fields = <String, String>{};
      if (username != null) {
        fields['username'] = username;
      }
      if (firstName != null) {
        fields['first_name'] = firstName;
      }
      if (lastName != null) {
        fields['last_name'] = lastName;
      }
      if (email != null) {
        fields['email'] = email;
      }
      if (avatarUrl != null) {
        fields['profile_picture'] = avatarUrl;
      }

      Map<String, dynamic> response;
      if (imageFile != null || avatarUrl != null) {
        final Map<String, http.MultipartFile> files = {};
        File? uploadFile = imageFile;

        // If it's an asset avatar, convert it to a temp file for uploading
        if (uploadFile == null && avatarUrl != null && avatarUrl.startsWith('assets/')) {
          try {
            final byteData = await rootBundle.load(avatarUrl);
            final bytes = byteData.buffer.asUint8List();
            final tempDir = await getTemporaryDirectory();
            final fileName = avatarUrl.split('/').last;
            final tempFile = File('${tempDir.path}/$fileName');
            await tempFile.writeAsBytes(bytes);
            uploadFile = tempFile;
          } catch (e) {
            debugPrint('Error converting asset to file: $e');
            // Fallback to sending it as a string field if conversion fails
          }
        }

        if (uploadFile != null) {
          files['profile_picture'] = await http.MultipartFile.fromPath(
            'profile_picture',
            uploadFile.path,
          );
        } else if (avatarUrl != null) {
          // Send as a string if it's a URL or if asset conversion failed
          fields['profile_picture'] = avatarUrl;
        }

        response = await _apiService.patchMultipart(
          ApiEndpoints.currentUser,
          fields: fields,
          files: files,
        );
      } else {
        response = await _apiService.patch(
          ApiEndpoints.currentUser,
          body: fields,
        );
      }

      final updatedUser = ApiUser.fromJson(response);
      
      // Update stored user data
      await _storage.write(
        key: _userKey,
        value: jsonEncode(updatedUser.toJson()),
      );

      return updatedUser;
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.message, statusCode: e.statusCode, data: e.data);
      }
      rethrow;
    }
  }

  /// Get stored device token ID
  Future<String?> getDeviceTokenId() async {
    return await _storage.read(key: _deviceTokenIdKey);
  }

  /// Store device token ID after registration
  Future<void> setDeviceTokenId(String tokenId) async {
    await _storage.write(key: _deviceTokenIdKey, value: tokenId);
  }
}
