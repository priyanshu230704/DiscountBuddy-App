import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../design/app_colors.dart';
import '../../design/app_radius.dart';
import 'package:discount_buddy/design/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_theme.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'login_page.dart';

/// Register Screen - NeoTaste style
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Step 0 Fields (Request OTP)
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  String _selectedRole = 'customer'; // 'customer' or 'merchant'
  bool _agreeToTerms = false;

  // Step 1 Fields (Verify & Complete)
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // State
  int _currentStep = 0; // 0: Request OTP, 1: Verify OTP, 2: Create Password
  bool _isLoading = false;
  bool _isFormValid = false;

  final AuthProvider _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();
    _authProvider.addListener(_authListener);
    _emailController.addListener(_validateForm);
    _otpController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_authListener);
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _otpFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _validateForm() {
    bool isValid = false;
    if (_currentStep == 0) {
      // Step 1: Email + Role + Terms
      isValid =
          _emailController.text.isNotEmpty &&
          _selectedRole.isNotEmpty &&
          _agreeToTerms &&
          RegExp(r'^[a-zA-Z0-9.@]*$').hasMatch(_emailController.text);
    } else if (_currentStep == 1) {
      // Step 2: OTP
      isValid = _otpController.text.length == 4;
    } else if (_currentStep == 2) {
      // Step 3: Password
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      
      final hasUppercase = password.contains(RegExp(r'[A-Z]'));
      final hasLowercase = password.contains(RegExp(r'[a-z]'));
      final hasDigits = password.contains(RegExp(r'[0-9]'));
      final hasMinLength = password.length >= 8;

      isValid = hasMinLength &&
          hasUppercase &&
          hasLowercase &&
          hasDigits &&
          confirmPassword == password;
    }

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _authListener() {
    if (!mounted) return;

    // Safety check for navigation and snackbars which must be outside build/layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
        return; // Exit after navigation
      }

      if (_authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _authProvider.errorMessage!,
              style: AuthTheme.bodyText,
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.medium,
            ),
          ),
        );
        _authProvider.clearError();
      }
    });

    final newIsLoading = _authProvider.isLoading;
    if (newIsLoading != _isLoading) {
      setState(() {
        _isLoading = newIsLoading;
      });
    }
  }

  void _sanitizeField(
    TextEditingController controller,
    RegExp allowedChars, {
    int? maxLength,
  }) {
    String currentText = controller.text;
    String sanitizedText = currentText
        .split('')
        .where((char) => allowedChars.hasMatch(char))
        .join('');

    if (maxLength != null && sanitizedText.length > maxLength) {
      sanitizedText = sanitizedText.substring(0, maxLength);
    }

    if (currentText != sanitizedText) {
      Future.delayed(Duration(milliseconds: 10), () {
        if (mounted && controller.text == currentText) {
          controller.value = controller.value.copyWith(
            text: sanitizedText,
            selection: TextSelection.collapsed(offset: sanitizedText.length),
          );
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_currentStep == 0) {
        // Request OTP
        final success = await _authProvider.registerInit(
          email: _emailController.text.trim(),
          role: _selectedRole,
        );
        if (success) {
          setState(() {
            _currentStep = 1;
            // Reset validation for next step
            _validateForm();
          });
          // Auto-focus OTP field
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) _otpFocusNode.requestFocus();
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'OTP code sent to ${_emailController.text}',
                  style: AuthTheme.bodyText,
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else if (_currentStep == 1) {
        // Verify OTP via Stage 2 Endpoint
        final success = await _authProvider.verifyOtp(
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
        );

        if (success) {
          setState(() {
            _currentStep = 2;
            _validateForm();
          });
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) _passwordFocusNode.requestFocus();
          });
        }
      } else {
        // Verify & Complete
        await _authProvider.registerComplete(
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
          password: _passwordController.text,
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    await _authProvider.loginWithGoogle();
  }

  Future<void> _handleAppleLogin() async {
    await _authProvider.loginWithApple();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    final scale = (MediaQuery.of(context).size.width / 390).clamp(0.7, 1.05);

    return PopScope(
      canPop: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.surface,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Stack(
            fit: StackFit.expand,
            children: [

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.background,
                        AppColors.surface,
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOutBack,
                        top: isKeyboardOpen ? -150 : -100,
                        right: isKeyboardOpen ? -100 : -50,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: isKeyboardOpen ? 0.6 : 1.0,
                          child: _StaticGlowBubble(
                            size: 450,
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOutBack,
                        bottom: isKeyboardOpen ? -150 : -80,
                        left: isKeyboardOpen ? -120 : -60,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: isKeyboardOpen ? 0.4 : 1.0,
                          child: _StaticGlowBubble(
                            size: 500,
                            color: AppColors.secondary.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating 3D Icons
              AnimatedPositioned(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                top: isKeyboardOpen ? 180 * scale : 240 * scale,
                left: isKeyboardOpen ? -40 * scale : -10 * scale,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: isKeyboardOpen ? 0.2 : 0.5,
                  child: _AnimatedIcon(
                    child: Image.asset(
                      'assets/png/sushi_icon.png',
                      width: 64 * scale,
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                top: isKeyboardOpen ? 300 * scale : 340 * scale,
                right: isKeyboardOpen ? -40 * scale : -10 * scale,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: isKeyboardOpen ? 0.15 : 0.4,
                  child: Image.asset(
                    'assets/png/burger_icon.png',
                    width: 72 * scale,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                top: isKeyboardOpen ? 120 * scale : 150 * scale,
                right: isKeyboardOpen ? 40 * scale : 20 * scale,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: isKeyboardOpen ? 0.3 : 0.6,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Image.asset(
                      'assets/png/discount_tag_icon.png',
                      width: 48 * scale,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
                  child: Image.asset(
                    'assets/png/login_bg_sparkly.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    24 + MediaQuery.of(context).padding.bottom + bottomInset,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            const SizedBox(height: 8),
                            Center(
                              child: Container(
                                width: (isKeyboardOpen ? 64 : 88) * scale,
                                height: (isKeyboardOpen ? 64 : 88) * scale,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    20 * scale,
                                  ),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPurple.withValues(
                                        alpha: 0.20,
                                      ),
                                      blurRadius: 25,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    18 * scale,
                                  ),
                                  child: Image.asset(
                                    'assets/png/db_logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.local_offer_rounded,
                                        color: AppColors.primaryPurple,
                                        size: 32,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _currentStep == 0
                                  ? 'Create your account'
                                  : _currentStep == 1
                                      ? 'Verify your account'
                                      : 'Set a password',
                              textAlign: TextAlign.center,
                              style: AppTypography.title.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentStep == 0
                                  ? 'Join DiscountBuddy and unlock local offers.'
                                  : _currentStep == 1
                                      ? 'Enter the OTP sent to your email.'
                                      : 'Create a secure password to finish.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                22,
                                20,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_currentStep == 0) ...[
                                    AuthTextField(
                                      controller: _emailController,
                                      placeholder: 'Email',
                                      keyboardType: TextInputType.emailAddress,
                                      focusNode: _emailFocusNode,
                                      onChanged: (value) {
                                        _sanitizeField(
                                          _emailController,
                                          RegExp(r'[a-zA-Z0-9.@]'),
                                        );
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!RegExp(
                                          r'^[a-zA-Z0-9.@]*$',
                                        ).hasMatch(value)) {
                                          return 'Only letters, numbers, . and @ are allowed';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'Choose account type',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildRoleOption(
                                            label: 'Customer',
                                            icon: Icons.person_outline_rounded,
                                            isSelected:
                                                _selectedRole == 'customer',
                                            onTap: () {
                                              setState(() {
                                                _selectedRole = 'customer';
                                                _validateForm();
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildRoleOption(
                                            label: 'Merchant',
                                            icon: Icons.storefront_outlined,
                                            isSelected:
                                                _selectedRole == 'merchant',
                                            onTap: () {
                                              setState(() {
                                                _selectedRole = 'merchant';
                                                _validateForm();
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _agreeToTerms = !_agreeToTerms;
                                          _validateForm();
                                        });
                                      },
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            width: 22,
                                            height: 22,
                                            margin: const EdgeInsets.only(
                                              top: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _agreeToTerms
                                                  ? AppColors.primaryPurple
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: _agreeToTerms
                                                    ? AppColors.primaryPurple
                                                    : AppColors.textDisabled,
                                                width: 1.6,
                                              ),
                                            ),
                                            child: _agreeToTerms
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 14,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'I agree to the Terms of Service and Privacy Policy',
                                              style: AppTypography.bodySmall.copyWith(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else if (_currentStep == 1) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPurple
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Code sent to ${_emailController.text}',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryPurple,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    AuthTextField(
                                      controller: _otpController,
                                      placeholder: '4-Digit Code',
                                      keyboardType: TextInputType.number,
                                      focusNode: _otpFocusNode,
                                      maxLength: 4,
                                      onChanged: (value) {
                                        _sanitizeField(
                                          _otpController,
                                          RegExp(r'[0-9]'),
                                          maxLength: 4,
                                        );
                                      },
                                      validator: (value) {
                                        if (value == null ||
                                            value.length != 4) {
                                          return 'Enter 4-digit code';
                                        }
                                        return null;
                                      },
                                    ),
                                  ] else if (_currentStep == 2) ...[
                                    AuthTextField(
                                      controller: _passwordController,
                                      placeholder: 'Create Password',
                                      obscureText: _obscurePassword,
                                      showToggle: true,
                                      focusNode: _passwordFocusNode,
                                      onToggleVisibility: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a password';
                                        }
                                        if (value.length < 8) {
                                          return 'Password must be at least 8 characters';
                                        }
                                        if (!value.contains(RegExp(r'[A-Z]'))) {
                                          return 'Must contain at least one capital letter';
                                        }
                                        if (!value.contains(RegExp(r'[a-z]'))) {
                                          return 'Must contain at least one small letter';
                                        }
                                        if (!value.contains(RegExp(r'[0-9]'))) {
                                          return 'Must contain at least one number';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    AuthTextField(
                                      controller: _confirmPasswordController,
                                      placeholder: 'Confirm Password',
                                      obscureText: _obscureConfirmPassword,
                                      showToggle: true,
                                      focusNode: _confirmPasswordFocusNode,
                                      onToggleVisibility: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  Opacity(
                                    opacity: _isFormValid && !_isLoading
                                        ? 1
                                        : 0.55,
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primaryPurple,
                                            AppColors.secondaryPink,
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryPurple
                                                .withValues(alpha: 0.28),
                                            blurRadius: 16,
                                            offset: const Offset(0, 7),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isFormValid && !_isLoading
                                            ? _handleSubmit
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          disabledBackgroundColor:
                                              Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                _currentStep == 0
                                                    ? 'Send Verification Code'
                                                    : _currentStep == 1
                                                        ? 'Verify Code'
                                                        : 'Complete Registration',
                                                style: AppTypography.bodySmall.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  if (_currentStep == 0 &&
                                      _selectedRole == 'customer') ...[
                                    const SizedBox(height: 22),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.textDisabled
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            'OR',
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textDisabled,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.textDisabled
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                      ],
                                    ),
                                     const SizedBox(height: 16),
                                     if (!kIsWeb && Platform.isAndroid)
                                       _buildFullSocialButton(
                                         icon: 'assets/svg/google.svg',
                                         label: 'Continue with Google',
                                         onPressed: _isLoading ? null : _handleGoogleLogin,
                                       )
                                     else
                                       Row(
                                         mainAxisAlignment: MainAxisAlignment.center,
                                         children: [
                                           _buildSocialIcon(
                                             icon: 'assets/svg/google.svg',
                                             onPressed: _isLoading ? null : _handleGoogleLogin,
                                           ),
                                           if (!kIsWeb && Platform.isIOS) ...[
                                             const SizedBox(width: 20),
                                             _buildSocialIcon(
                                               icon: 'assets/svg/apple.svg',
                                               onPressed: _isLoading ? null : _handleAppleLogin,
                                             ),
                                           ],
                                         ],
                                       ),
                                   ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account?',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                  ) => const LoginPage(),
                                              transitionsBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child,
                                                  ) {
                                                    return SlideTransition(
                                                      position:
                                                          Tween<Offset>(
                                                            begin: const Offset(
                                                              1.0,
                                                              0.0,
                                                            ),
                                                            end: Offset.zero,
                                                          ).animate(
                                                            CurvedAnimation(
                                                              parent: animation,
                                                              curve: Curves
                                                                  .easeInOut,
                                                            ),
                                                          ),
                                                      child: child,
                                                    );
                                                  },
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Log in',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.primaryPurple,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon({
    required String icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textDisabled.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 22,
            height: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildFullSocialButton({
    required String icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textDisabled.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? AppColors.primaryPurple.withValues(alpha: 0.10)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple
                : AppColors.textDisabled.withValues(alpha: 0.35),
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected
                  ? AppColors.primaryPurple
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedIcon extends StatelessWidget {
  final Widget child;
  const _AnimatedIcon({required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Transform.translate(
        offset: const Offset(0, 4),
        child: child,
      ),
    );
  }
}

class _StaticGlowBubble extends StatelessWidget {
  const _StaticGlowBubble({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
