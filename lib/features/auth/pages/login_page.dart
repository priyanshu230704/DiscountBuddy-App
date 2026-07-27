import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:discount_buddy/features/auth/data/auth_provider.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/core/theme/app_typography.dart';
import 'package:discount_buddy/features/auth/widgets/auth_theme.dart';
import 'package:discount_buddy/widgets/connectivity_gate.dart';

/// Login Screen - DiscountBuddy Redesign
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isFormValid = false;
  
  final GlobalKey<FormFieldState> _emailKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _passwordKey = GlobalKey<FormFieldState>();

  final AuthProvider _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();
    _authProvider.addListener(_authListener);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_authListener);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
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
        Get.offAllNamed(AppRoutes.home);
        return;
      }

      if (_authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _authProvider.errorMessage!,
              style: AuthTheme.bodyText,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _authProvider.clearError();
      }
    });

    // setState is fine here as it's a listener, but good to be defensive
    final newIsLoading = _authProvider.isLoading;
    if (newIsLoading != _isLoading) {
      setState(() {
        _isLoading = newIsLoading;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await _authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final success = await _authProvider.loginWithGoogle();
    if (!success && mounted && _authProvider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google sign-in was canceled. Please choose an account to continue.',
            style: AuthTheme.bodyText,
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleAppleLogin() async {
    final success = await _authProvider.loginWithApple();
    if (!success && mounted && _authProvider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Apple sign-in was canceled.',
            style: AuthTheme.bodyText,
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    Get.toNamed(
      AppRoutes.forgotPassword,
      arguments: email.isNotEmpty ? email : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return PopScope(
      canPop: true,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: ConnectivityGate(
          child: Stack(
          children: [
            // Premium Mesh Gradient Background
            Positioned.fill(
              child: Container(
                decoration:  BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEDE7FF),
                      Color(0xFFFFF2F9),
                      Color(0xFFF0F7FF),
                    ],
                  ),
                ),
              ),
            ),
            
            // Decorative glows: static (no repeat controller) — avoids constant
            // repaints / BLAST buffer pressure on some Android devices.
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

            // Sparkly Overlay (Subtle)
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Image.asset(
                  'assets/png/login_bg_sparkly.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>  SizedBox(),
                ),
              ),
            ),

            LayoutBuilder(
              key:  ValueKey('login_layout_builder'),
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final scale = (width / 390).clamp(0.7, 1.05);
                final cardMaxWidth = 400.0 * scale;

                return SizedBox(
                  height: constraints.maxHeight,
                  width: constraints.maxWidth,
                  child: Stack(
                    children: [
                      // Floating 3D Icons (Animated & Smoother)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        top: isKeyboardOpen ? 180 * scale : 240 * scale,
                        left: isKeyboardOpen ? -40 * scale : -10 * scale,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: isKeyboardOpen ? 0.2 : 0.5,
                          child: _AnimatedIcon(
                            child: Image.asset('assets/png/sushi_icon.png', width: 64 * scale),
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
                          child: Image.asset('assets/png/burger_icon.png', width: 72 * scale),
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
                            child: Image.asset('assets/png/discount_tag_icon.png', width: 48 * scale),
                          ),
                        ),
                      ),
                      
                      SafeArea(
                        key:  ValueKey('login_safe_area'),
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: (isKeyboardOpen ? 20 : 60) * scale),
                                  

                                SizedBox(height: 16 * scale),
                                
                                // Logo and Text Section
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Logo with Glow (Animated)
                                    Center(
                                      child: AnimatedContainer(
                                        duration:  Duration(milliseconds: 300),
                                        curve: Curves.easeOutCubic,
                                        width: (isKeyboardOpen ? 64 : 88) * scale,
                                        height: (isKeyboardOpen ? 64 : 88) * scale,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20 * scale),
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.12),
                                              blurRadius: 25,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.zero,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(18 * scale),
                                          child: Image.asset(
                                            'assets/png/db_logo.png',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => 
                                               Icon(Icons.fastfood_rounded, color: Color(0xFF8B5CF6)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    SizedBox(height: (isKeyboardOpen ? 8 : 14) * scale),
                                    
                                    Text(
                                      'Welcome back',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.title.copyWith(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                    
                                    if (!isKeyboardOpen) ...[
                                      SizedBox(height: 6 * scale),
                                      Text(
                                        'Ready for amazing deals? 🍜\nLog in and start exploring now.',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                                          fontSize: 16 * scale,
                                          height: 1.3,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                
                                 SizedBox(height: 32 * scale),
                                
                                // Main Card
                                Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: cardMaxWidth),
                                    child: Container(
                                      key:  ValueKey('login_main_card'),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(32 * scale),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.textPrimary.withValues(alpha: 0.08),
                                            blurRadius: 40,
                                            offset: const Offset(0, 15),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 28 * scale,
                                        vertical: (isKeyboardOpen ? 24 : 32) * scale,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _buildInputField(
                                            key: _emailKey,
                                            controller: _emailController,
                                            hintText: 'Email / Mobile',
                                            keyboardType: TextInputType.emailAddress,
                                            focusNode: _emailFocusNode,
                                            scale: scale,
                                            isSmall: isKeyboardOpen,
                                          ),
                                          SizedBox(height: 16 * scale),
                                          _buildInputField(
                                            key: _passwordKey,
                                            controller: _passwordController,
                                            hintText: 'Password',
                                            obscureText: _obscurePassword,
                                            focusNode: _passwordFocusNode,
                                            scale: scale,
                                            isSmall: isKeyboardOpen,
                                            suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword = !_obscurePassword;
                                                });
                                              },
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                                color: AppColors.textDisabled,
                                                size: 20 * scale,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 18 * scale),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: _handleForgotPassword,
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                'Forgot password?',
                                                style: AppTypography.bodySmall.copyWith(
                                                  fontSize: 14,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 18 * scale),
                                          // Login Button (Animated)
                                          AnimatedContainer(
                                            duration:  Duration(milliseconds: 300),
                                            curve: Curves.easeOutCubic,
                                            height: (isKeyboardOpen ? 48 : 56) * scale,
                                            decoration: BoxDecoration(
                                              gradient: AppColors.purpleGradient,
                                            borderRadius: BorderRadius.circular(18 * scale),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.25),
                                                blurRadius: 15,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: _isFormValid && !_isLoading ? _handleLogin : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                foregroundColor: Colors.white,
                                                disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                                                shadowColor: Colors.transparent,
                                                padding: EdgeInsets.zero, // Important for scaling
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(18 * scale),
                                                ),
                                              ),
                                              child: _isLoading
                                                  ? SizedBox(
                                                      width: 22 * scale,
                                                      height: 22 * scale,
                                                      child: const CircularProgressIndicator(
                                                  color: AppColors.white,
                                                  strokeWidth: 2,
                                                ),
                                                    )
                                                  : Text(
                                                      'Log In',
                                                      style: AppTypography.title.copyWith(
                                                        fontSize: 18,
                                                        color: AppColors.white,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          SizedBox(height: (isKeyboardOpen ? 18 : 24) * scale),
                                          Row(
                                            children: [
                                              Expanded(child: Divider(color: AppColors.textDisabled.withValues(alpha: 0.3))),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                child: Text(
                                                  'OR',
                                                     style: AppTypography.bodySmall.copyWith(
                                                       color: AppColors.textDisabled,
                                                       fontWeight: FontWeight.w700,
                                                       fontSize: 12 * scale,
                                                     ),
                                                ),
                                              ),
                                              Expanded(child: Divider(color: AppColors.textDisabled.withValues(alpha: 0.3))),
                                            ],
                                          ),
                                          SizedBox(height: (isKeyboardOpen ? 18 : 24) * scale),
                                          if (!kIsWeb && Platform.isAndroid)
                                            _buildFullSocialButton(
                                              icon: 'assets/svg/google.svg',
                                              label: 'Continue with Google',
                                              onPressed: _isLoading ? null : _handleGoogleLogin,
                                              scale: scale,
                                            )
                                          else
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                _buildSocialIcon(
                                                  icon: 'assets/svg/google.svg',
                                                  onPressed: _isLoading ? null : _handleGoogleLogin,
                                                  scale: scale,
                                                ),
                                                if (!kIsWeb && Platform.isIOS) ...[
                                                  SizedBox(width: 24 * scale),
                                                  _buildSocialIcon(
                                                    icon: 'assets/svg/apple.svg',
                                                    onPressed: _isLoading ? null : _handleAppleLogin,
                                                    scale: scale,
                                                  ),
                                                ],
                                              ],
                                            ),
                                           SizedBox(height: 18 * scale),
                                          // NEW HERE? CREATE ACCOUNT
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'New here?',
                                                 style: AppTypography.bodySmall.copyWith(
                                                   color: AppColors.textSecondary.withValues(alpha: 0.8),
                                                   fontSize: 14 * scale,
                                                   fontWeight: FontWeight.w500,
                                                 ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Get.toNamed(AppRoutes.register);
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: Text(
                                                  'Create account',
                                                  style: AppTypography.bodySmall.copyWith(
                                                    color: AppColors.primaryPurple,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                 SizedBox(height: 40 * scale),
                                
                                  SizedBox(height: (isKeyboardOpen ? 30 : 60) * scale),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),


                    ],
                  ),
                );
              },
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
    required double scale,
  }) {
    return Container(
      width: 60 * scale,
      height: 60 * scale,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: AppColors.textDisabled.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16 * scale),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 24 * scale,
            height: 24 * scale,
          ),
        ),
      ),
    );
  }

  Widget _buildFullSocialButton({
    required String icon,
    required String label,
    required VoidCallback? onPressed,
    required double scale,
  }) {
    return Container(
      width: double.infinity,
      height: 56 * scale,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: AppColors.textDisabled.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16 * scale),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 24 * scale,
              height: 24 * scale,
            ),
            SizedBox(width: 12 * scale),
            Text(
              label,
               style: AppTypography.body.copyWith(
                 color: AppColors.textPrimary,
                 fontSize: 16 * scale,
                 fontWeight: FontWeight.w600,
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    Key? key,
    required TextEditingController controller,
    required String hintText,
    required FocusNode focusNode,
    required double scale,
    bool isSmall = false,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: AppTypography.body.copyWith(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textDisabled,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18 * scale,
          vertical: (isSmall ? 14 : 16) * scale,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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
