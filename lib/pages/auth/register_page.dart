import 'package:discount_buddy/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_theme.dart';
import '../../widgets/auth/auth_button.dart';
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
  int _currentStep = 0; // 0: Request OTP, 1: Complete Registration
  bool _isLoading = false;
  bool _isFormValid = false;

  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _otpController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_authListener);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider ??= AuthProvider();
    _authProvider!.addListener(_authListener);
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
    } else {
      // Step 2: OTP + Password
      isValid =
          _otpController.text.length == 4 &&
          _passwordController.text.length >= 6 &&
          _confirmPasswordController.text == _passwordController.text;
    }

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _authListener() {
    if (!mounted) return;
    if (_authProvider?.isAuthenticated ?? false) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if ((_authProvider?.isLoading ?? false) != _isLoading) {
      setState(() {
        _isLoading = _authProvider?.isLoading ?? false;
      });
    }

    if (_authProvider?.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authProvider!.errorMessage!,
            style: AuthTheme.bodyText,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      _authProvider?.clearError();
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
      Future.delayed( Duration(milliseconds: 1000), () {
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
    if (_formKey.currentState!.validate() && _authProvider != null) {
      if (_currentStep == 0) {
        // Request OTP
        final success = await _authProvider!.registerInit(
          email: _emailController.text.trim(),
          role: _selectedRole,
        );
        if (success) {
          setState(() {
            _currentStep = 1;
            // Reset validation for next step
            _isFormValid = false;
          });
          // Auto-focus OTP field
          Future.delayed( Duration(milliseconds: 300), () {
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
      } else {
        // Verify & Complete
        await _authProvider!.registerComplete(
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
          password: _passwordController.text,
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_authProvider != null) {
      await _authProvider!.loginWithGoogle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AuthTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _currentStep > 0
              ? IconButton(
                  icon:  Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                      _validateForm();
                    });
                  },
                )
              : null,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics:
                 ClampingScrollPhysics(), // Allow scrolling if keyboard opens
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text('Create your account', style: AuthTheme.headingLarge),
                   SizedBox(height: 8),

                  // Subtitle
                  Text(
                    _currentStep == 0
                        ? 'Unlock exclusive restaurant offers'
                        : 'Enter the code sent to your email',
                    style: AuthTheme.subtitle,
                  ),
                   SizedBox(height: 48),

                  if (_currentStep == 0) ...[
                    // --- STEP 1: Email & Role ---

                    // Email / Mobile Input
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
                        if (!RegExp(r'^[a-zA-Z0-9.@]*$').hasMatch(value)) {
                          return 'Only letters, numbers, . and @ are allowed';
                        }
                        return null;
                      },
                    ),
                     SizedBox(height: 24),

                    // Role Selection
                    Text(
                      'Account Type',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                     SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRole = 'customer';
                                _validateForm();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'customer'
                                    ? AppColors.accent.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedRole == 'customer'
                                      ? AppColors.accent
                                      : AppColors.textDisabled.withValues(
                                          alpha: 0.3,
                                        ),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    color: _selectedRole == 'customer'
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                    size: 28,
                                  ),
                                   SizedBox(height: 8),
                                  Text(
                                    'Customer',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedRole == 'customer'
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                         SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRole = 'merchant';
                                _validateForm();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'merchant'
                                    ? AppColors.accent.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedRole == 'merchant'
                                      ? AppColors.accent
                                      : AppColors.textDisabled.withValues(
                                          alpha: 0.3,
                                        ),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.store_outlined,
                                    color: _selectedRole == 'merchant'
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                    size: 28,
                                  ),
                                   SizedBox(height: 8),
                                  Text(
                                    'Merchant',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedRole == 'merchant'
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                     SizedBox(height: 24),

                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreeToTerms = !_agreeToTerms;
                              _validateForm();
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: _agreeToTerms
                                  ? AuthTheme.accent
                                  : Colors.transparent,
                              border: Border.all(
                                color: _agreeToTerms
                                    ? AuthTheme.accent
                                    : AuthTheme.textGrey,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _agreeToTerms
                                ?  Icon(
                                    Icons.check,
                                    color: AuthTheme.background,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                         SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreeToTerms = !_agreeToTerms;
                                _validateForm();
                              });
                            },
                            child: Text(
                              'I agree to the Terms of Service & Privacy Policy',
                              style: AuthTheme.subtitle.copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // --- STEP 2: OTP & Password ---
                    Text(
                      'Sent to ${_emailController.text}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                     SizedBox(height: 24),

                    // OTP Input
                    AuthTextField(
                      controller: _otpController,
                      placeholder: '4-Digit Code',
                      keyboardType: TextInputType.number,
                      focusNode: _otpFocusNode,
                      maxLength: 4,
                      onChanged: (value) {
                        // Only numbers
                        _sanitizeField(
                          _otpController,
                          RegExp(r'[0-9]'),
                          maxLength: 4,
                        );
                      },
                      validator: (value) {
                        if (value == null || value.length != 4) {
                          return 'Enter 4-digit code';
                        }
                        return null;
                      },
                    ),
                     SizedBox(height: 16),

                    // Password Input
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
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                     SizedBox(height: 16),

                    // Confirm Password Input
                    AuthTextField(
                      controller: _confirmPasswordController,
                      placeholder: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      showToggle: true,
                      focusNode: _confirmPasswordFocusNode,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
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

                   SizedBox(height: 32),

                  // Action Button
                  AuthButton(
                    text: _currentStep == 0
                        ? 'Send Verification Code'
                        : 'Complete Registration',
                    onPressed: _isFormValid && !_isLoading
                        ? _handleSubmit
                        : null,
                    isLoading: _isLoading,
                  ),

                  // Back to Login (Only show on step 0 to avoid navigation confusion, or keep it?)
                  if (_currentStep == 0) ...[
                     SizedBox(height: 24),

                    // OR Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                     SizedBox(height: 24),

                    // Google Login Button
                    OutlinedButton(
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Text(
                            'G',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                           SizedBox(width: 12),
                           Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                     SizedBox(height: 24),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: AuthTheme.subtitle,
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                         LoginPage(),
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
                                              begin:  Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeInOut,
                                              ),
                                            ),
                                        child: child,
                                      );
                                    },
                              ),
                            );
                          },
                          child: Text('Log in', style: AuthTheme.linkText),
                        ),
                      ],
                    ),
                     SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
