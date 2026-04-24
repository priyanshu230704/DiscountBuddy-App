import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../design/app_radius.dart';
import 'package:discount_buddy/design/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_gradient_button.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  int _currentStep = 0; // 0: Request OTP, 1: Verify OTP
  bool _isLoading = false;
  bool _isFormValid = false;

  final AuthProvider _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
    _authProvider.addListener(_authListener);
    _emailController.addListener(_validateForm);
    _otpController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_authListener);
    _emailController.dispose();
    _otpController.dispose();
    _emailFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _validateForm() {
    bool isValid = false;
    if (_currentStep == 0) {
      isValid =
          _emailController.text.isNotEmpty &&
          RegExp(
            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
          ).hasMatch(_emailController.text);
    } else {
      isValid = _otpController.text.length == 4;
    }

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _authListener() {
    if (!mounted) return;
    final newIsLoading = _authProvider.isLoading;
    if (newIsLoading != _isLoading) {
      setState(() {
        _isLoading = newIsLoading;
      });
    }

    if (_authProvider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authProvider.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
          ),
        );
        _authProvider.clearError();
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentStep == 0) {
      final success = await _authProvider.requestPasswordResetOtp(
        email: _emailController.text.trim(),
      );
      if (success) {
        setState(() {
          _currentStep = 1;
          _isFormValid = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('OTP code sent to your email'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
          ),
        );
      }
    } else {
      // Step 2: Verify OTP Only
      final success = await _authProvider.verifyPasswordResetOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );

      if (success && mounted) {
        // Navigate to the third page for password creation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(
              email: _emailController.text.trim(),
              otp: _otpController.text.trim(),
            ),
          ),
        ).then((wasReset) {
          if (wasReset == true && mounted) {
            Navigator.pop(context); // Close the OTP page too
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return AppScaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Decorative Glow Bubbles
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutBack,
            top: isKeyboardOpen ? -200 : -100,
            right: -80,
            child: _GlowBubble(
              size: 450,
              color: AppColors.primaryPurple.withValues(alpha: 0.2),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutBack,
            bottom: isKeyboardOpen ? -200 : -100,
            left: -100,
            child: _GlowBubble(
              size: 500,
              color: AppColors.secondaryPink.withValues(alpha: 0.15),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(
                          _currentStep == 0
                              ? Icons.lock_open_rounded
                              : Icons.shield_rounded,
                          size: 48,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _currentStep == 0 ? 'Reset Password' : 'Verify Code',
                      textAlign: TextAlign.center,
                      style: AppTypography.title.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _currentStep == 0
                            ? 'Enter your email address and we\'ll send you a 4-digit code to reset your password.'
                            : 'We\'ve sent a verification code to ${_emailController.text}',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Glassmorphic-style container for inputs
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (_currentStep == 0)
                            AuthTextField(
                              controller: _emailController,
                              placeholder: 'Email Address',
                              keyboardType: TextInputType.emailAddress,
                              focusNode: _emailFocusNode,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Please enter email';
                                return null;
                              },
                            )
                          else ...[
                            AuthTextField(
                              controller: _otpController,
                              placeholder: '4-Digit OTP',
                              keyboardType: TextInputType.number,
                              focusNode: _otpFocusNode,
                              maxLength: 4,
                              validator: (value) {
                                if (value == null || value.length != 4)
                                  return 'Enter 4-digit code';
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 32),
                          AppGradientButton(
                            onPressed: _isFormValid && !_isLoading
                                ? _handleSubmit
                                : null,
                            isLoading: _isLoading,
                            width: double.infinity,
                            child: Text(
                              _currentStep == 0
                                  ? 'Send Verification Code'
                                  : 'Verify OTP',
                              style: AppTypography.button.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
      ),
    );
  }
}
