import 'dart:io';

import 'package:discount_buddy/features/auth/data/auth_repository_impl.dart';
import 'package:discount_buddy/features/auth/data/device_token_adapter.dart';
import 'package:discount_buddy/features/auth/domain/entities/auth_session.dart';
import 'package:discount_buddy/features/auth/domain/entities/user_entity.dart';
import 'package:discount_buddy/features/auth/domain/failures/auth_failure.dart';
import 'package:discount_buddy/features/auth/domain/failures/failure.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';
import 'package:discount_buddy/features/auth/domain/usecases/check_username_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/complete_registration_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/confirm_password_reset_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/delete_account_init_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/initialize_session_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/login_with_apple_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/logout_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/register_with_password_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/request_password_reset_email_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/request_password_reset_otp_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/resend_registration_otp_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/start_registration_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/verify_password_reset_otp_usecase.dart';
import 'package:discount_buddy/features/auth/domain/usecases/verify_registration_otp_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Presentation state for auth. Holds state, calls one use case, maps [Result].
class AuthProvider extends ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;

  AuthProvider._internal() {
    final repo = AuthRepositoryImpl();
    final tokens = DeviceTokenAdapter();

    _getCurrentUserUseCase = GetCurrentUserUseCase(repo);
    _refreshTokenUseCase = RefreshTokenUseCase(repo);
    _initializeSessionUseCase = InitializeSessionUseCase(
      repo,
      _refreshTokenUseCase,
      _getCurrentUserUseCase,
    );
    _loginWithEmailUseCase = LoginWithEmailUseCase(
      repo,
      tokens,
      getCurrentUser: _getCurrentUserUseCase,
    );
    _loginWithGoogleUseCase = LoginWithGoogleUseCase(
      repo,
      tokens,
      getCurrentUser: _getCurrentUserUseCase,
    );
    _loginWithAppleUseCase = LoginWithAppleUseCase(
      repo,
      tokens,
      getCurrentUser: _getCurrentUserUseCase,
    );
    _startRegistrationUseCase = StartRegistrationUseCase(repo);
    _verifyRegistrationOtpUseCase = VerifyRegistrationOtpUseCase(repo);
    _resendRegistrationOtpUseCase = ResendRegistrationOtpUseCase(repo);
    _completeRegistrationUseCase = CompleteRegistrationUseCase(
      repo,
      tokens,
      getCurrentUser: _getCurrentUserUseCase,
    );
    _checkUsernameUseCase = CheckUsernameUseCase(repo);
    _registerWithPasswordUseCase = RegisterWithPasswordUseCase(
      repo,
      tokens,
      getCurrentUser: _getCurrentUserUseCase,
    );
    _logoutUseCase = LogoutUseCase(repo, tokens);
    _requestPasswordResetOtpUseCase = RequestPasswordResetOtpUseCase(repo);
    _verifyPasswordResetOtpUseCase = VerifyPasswordResetOtpUseCase(repo);
    _confirmPasswordResetUseCase = ConfirmPasswordResetUseCase(repo);
    _requestPasswordResetEmailUseCase = RequestPasswordResetEmailUseCase(repo);
    _updateProfileUseCase = UpdateProfileUseCase(repo);
    _deleteAccountInitUseCase = DeleteAccountInitUseCase(repo);
    _deleteAccountUseCase = DeleteAccountUseCase(repo);

    _bootstrapSession();
  }

  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final RefreshTokenUseCase _refreshTokenUseCase;
  late final InitializeSessionUseCase _initializeSessionUseCase;
  late final LoginWithEmailUseCase _loginWithEmailUseCase;
  late final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  late final LoginWithAppleUseCase _loginWithAppleUseCase;
  late final StartRegistrationUseCase _startRegistrationUseCase;
  late final VerifyRegistrationOtpUseCase _verifyRegistrationOtpUseCase;
  late final ResendRegistrationOtpUseCase _resendRegistrationOtpUseCase;
  late final CompleteRegistrationUseCase _completeRegistrationUseCase;
  late final CheckUsernameUseCase _checkUsernameUseCase;
  late final RegisterWithPasswordUseCase _registerWithPasswordUseCase;
  late final LogoutUseCase _logoutUseCase;
  late final RequestPasswordResetOtpUseCase _requestPasswordResetOtpUseCase;
  late final VerifyPasswordResetOtpUseCase _verifyPasswordResetOtpUseCase;
  late final ConfirmPasswordResetUseCase _confirmPasswordResetUseCase;
  late final RequestPasswordResetEmailUseCase _requestPasswordResetEmailUseCase;
  late final UpdateProfileUseCase _updateProfileUseCase;
  late final DeleteAccountInitUseCase _deleteAccountInitUseCase;
  late final DeleteAccountUseCase _deleteAccountUseCase;

  final Rxn<UserEntity> _user = Rxn<UserEntity>();
  final RxBool _isLoading = false.obs;
  final RxBool _isAuthenticated = false.obs;
  final RxnString _errorMessage = RxnString();
  final RxString _userRole = 'customer'.obs;
  final RxBool _isGuestMode = false.obs;

  /// Domain user — UI should use [UserEntity], not API DTOs.
  UserEntity? get user => _user.value;
  bool get isLoading => _isLoading.value;
  bool get isAuthenticated => _isAuthenticated.value;
  String? get errorMessage => _errorMessage.value;
  String get userRole => _userRole.value;
  bool get isGuestMode => _isGuestMode.value;
  bool get isMerchant => _userRole.value == 'merchant';
  bool get isCustomer =>
      _userRole.value == 'customer' || _userRole.value == 'mystery_guest';
  bool get isMysteryGuest => _userRole.value == 'mystery_guest';

  void _setLoading(bool value) {
    _isLoading.value = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage.value = null;
    notifyListeners();
  }

  void _applyFailure(Failure failure, {bool clearAuth = false}) {
    // Cancelled social login: stop loading, no snackbar message.
    _errorMessage.value = failure is CancelledFailure ? null : failure.message;
    if (clearAuth) {
      _isAuthenticated.value = false;
    }
    _isLoading.value = false;
    notifyListeners();
  }

  bool _applySessionResult(Result<AuthSession> result) {
    return result.fold(
      onSuccess: (session) {
        _user.value = session.user;
        _userRole.value = session.role;
        _isAuthenticated.value = true;
        _isGuestMode.value = false;
        _errorMessage.value = null;
        _isLoading.value = false;
        notifyListeners();
        return true;
      },
      onError: (failure) {
        _applyFailure(failure, clearAuth: true);
        return false;
      },
    );
  }

  bool _applyVoidResult(Result<void> result) {
    return result.fold(
      onSuccess: (_) {
        _errorMessage.value = null;
        _isLoading.value = false;
        notifyListeners();
        return true;
      },
      onError: (failure) {
        _applyFailure(failure);
        return false;
      },
    );
  }

  Future<void> _bootstrapSession() async {
    _setLoading(true);
    final result = await _initializeSessionUseCase();
    result.fold(
      onSuccess: (session) {
        if (session != null) {
          _user.value = session.user;
          _userRole.value = session.role;
          _isAuthenticated.value = true;
          debugPrint(
            'DEBUG AuthProvider: session restored as ${session.user.email}, '
            'role=${session.role}',
          );
        } else {
          _isAuthenticated.value = false;
          _userRole.value = 'customer';
        }
        _isLoading.value = false;
        notifyListeners();
      },
      onError: (failure) {
        _errorMessage.value = 'Failed to initialize authentication';
        _isAuthenticated.value = false;
        _isLoading.value = false;
        notifyListeners();
        debugPrint('DEBUG AuthProvider bootstrap: ${failure.message}');
      },
    );
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    clearError();
    final result = await _registerWithPasswordUseCase(
      email: email,
      username: username,
      password: password,
      role: role,
    );
    return _applySessionResult(result);
  }

  Future<bool> registerInit({
    required String email,
    required String role,
  }) async {
    _setLoading(true);
    clearError();
    final result = await _startRegistrationUseCase(email: email, role: role);
    return _applyVoidResult(result);
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    clearError();
    final result =
        await _verifyRegistrationOtpUseCase(email: email, otp: otp);
    return _applyVoidResult(result);
  }

  Future<Map<String, dynamic>> resendOtp({required String email}) async {
    final result = await _resendRegistrationOtpUseCase(email: email);
    return result.fold(
      onSuccess: (info) => info.toLegacyMap(),
      onError: (failure) => {
        'success': false,
        'detail': failure.message,
      },
    );
  }

  Future<bool> registerComplete({
    required String email,
    required String otp,
    required String password,
    String? username,
  }) async {
    _setLoading(true);
    clearError();
    final result = await _completeRegistrationUseCase(
      email: email,
      otp: otp,
      password: password,
      username: username,
    );
    return _applySessionResult(result);
  }

  Future<Map<String, dynamic>> checkUsernameAvailability(
    String username,
  ) async {
    final result = await _checkUsernameUseCase(username);
    return result.fold(
      onSuccess: (info) => info.toLegacyMap(),
      onError: (failure) => {
        'available': false,
        'error': failure.message,
      },
    );
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    clearError();
    final result = await _loginWithEmailUseCase(
      email: email,
      password: password,
    );
    return _applySessionResult(result);
  }

  Future<bool> loginWithGoogle() async {
    debugPrint('DEBUG: AuthProvider.loginWithGoogle -> Triggered');
    _setLoading(true);
    clearError();
    final result = await _loginWithGoogleUseCase();
    return _applySessionResult(result);
  }

  Future<bool> loginWithApple() async {
    debugPrint('DEBUG: AuthProvider.loginWithApple -> Triggered');
    _setLoading(true);
    clearError();
    final result = await _loginWithAppleUseCase();
    return _applySessionResult(result);
  }

  Future<void> logout() async {
    _setLoading(true);
    await _logoutUseCase();
    _user.value = null;
    _isAuthenticated.value = false;
    _isGuestMode.value = false;
    _userRole.value = 'customer';
    _errorMessage.value = null;
    _isLoading.value = false;
    notifyListeners();
  }

  void skipLogin() {
    _isGuestMode.value = true;
    _isAuthenticated.value = false;
    _user.value = null;
    _userRole.value = 'customer';
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final result = await _getCurrentUserUseCase();
    result.fold(
      onSuccess: (UserEntity? entity) {
        if (entity != null) {
          _user.value = entity;
          _userRole.value = entity.role;
          notifyListeners();
        }
      },
      onError: (failure) {
        if (failure is UnauthorizedFailure) {
          // Local session already cleared inside GetCurrentUserUseCase.
          debugPrint(
            'DEBUG AuthProvider.refreshUser: Unauthorized — clearing UI state',
          );
          _user.value = null;
          _isAuthenticated.value = false;
          _isGuestMode.value = false;
          _userRole.value = 'customer';
          notifyListeners();
        } else {
          debugPrint(
            'DEBUG AuthProvider.refreshUser: ${failure.message} — keeping session',
          );
        }
      },
    );
  }

  Future<bool> requestPasswordResetOtp({required String email}) async {
    _setLoading(true);
    clearError();
    final result = await _requestPasswordResetOtpUseCase(email: email);
    return _applyVoidResult(result);
  }

  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    clearError();
    final result =
        await _verifyPasswordResetOtpUseCase(email: email, otp: otp);
    return _applyVoidResult(result);
  }

  Future<bool> confirmPasswordReset({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    clearError();
    final result = await _confirmPasswordResetUseCase(
      email: email,
      otp: otp,
      password: password,
      confirmPassword: confirmPassword,
    );
    return _applyVoidResult(result);
  }

  Future<bool> forgotPassword({required String email}) async {
    _setLoading(true);
    clearError();
    final result = await _requestPasswordResetEmailUseCase(email: email);
    return _applyVoidResult(result);
  }

  Future<bool> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    File? imageFile,
    String? avatarUrl,
  }) async {
    _setLoading(true);
    clearError();
    final result = await _updateProfileUseCase(
      username: username,
      firstName: firstName,
      lastName: lastName,
      email: email,
      imageFile: imageFile,
      avatarUrl: avatarUrl,
    );
    return result.fold(
      onSuccess: (entity) {
        _user.value = entity;
        _userRole.value = entity.role;
        _errorMessage.value = null;
        _isLoading.value = false;
        notifyListeners();
        return true;
      },
      onError: (failure) {
        _applyFailure(failure);
        return false;
      },
    );
  }

  Future<bool> deleteAccountInit() async {
    _setLoading(true);
    clearError();
    final result = await _deleteAccountInitUseCase();
    return _applyVoidResult(result);
  }

  Future<bool> deleteAccount({required String otp}) async {
    _setLoading(true);
    clearError();
    final result = await _deleteAccountUseCase(otp: otp);
    return result.fold(
      onSuccess: (_) {
        _user.value = null;
        _isAuthenticated.value = false;
        _userRole.value = 'customer';
        _errorMessage.value = null;
        _isLoading.value = false;
        notifyListeners();
        return true;
      },
      onError: (failure) {
        _applyFailure(failure);
        return false;
      },
    );
  }
}
