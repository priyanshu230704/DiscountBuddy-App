import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'register_page.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/auth/auth_theme.dart';

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

  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_authListener);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider ??= AuthProvider();
    _authProvider!.addListener(_authListener);
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

      if (_authProvider?.isAuthenticated ?? false) {
        Navigator.of(context).pushReplacementNamed('/home');
        return; // Exit after navigation
      }

      if (_authProvider?.errorMessage != null) {
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
    });

    // setState is fine here as it's a listener, but good to be defensive
    final newIsLoading = _authProvider?.isLoading ?? false;
    if (newIsLoading != _isLoading) {
      setState(() {
        _isLoading = newIsLoading;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate() && _authProvider != null) {
      await _authProvider!.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_authProvider != null) {
      final success = await _authProvider!.loginWithGoogle();
      if (!success && mounted && _authProvider!.errorMessage == null) {
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
  }

  Future<void> _handleAppleLogin() async {
    if (_authProvider != null) {
      final success = await _authProvider!.loginWithApple();
      if (!success && mounted && _authProvider!.errorMessage == null) {
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
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your email address first',
            style: AuthTheme.bodyText,
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await _authProvider?.forgotPassword(email: email);
    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset link sent to your email',
            style: AuthTheme.bodyText,
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return PopScope(
      canPop: true,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
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
            
            // Decorative Glow Bubbles (Mesh effect - Animated)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOutBack,
              top: isKeyboardOpen ? -150 : -100,
              right: isKeyboardOpen ? -100 : -50,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: isKeyboardOpen ? 0.6 : 1.0,
                child: _GlowBubble(
                  size: 450,
                  color: AppColors.primary.withValues(alpha: 0.35),
                  shimmer: true,
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
                child: _GlowBubble(
                  size: 500,
                  color: AppColors.secondary.withValues(alpha: 0.25),
                  shimmer: true,
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
                                      style: AppFonts.titleStyle(
                                        color:  Color(0xFF1B1436),
                                        fontSize: (isKeyboardOpen ? 24 : 32) * scale,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                    
                                    if (!isKeyboardOpen) ...[
                                      SizedBox(height: 6 * scale),
                                      Text(
                                        'Ready for amazing deals? 🍜\nLog in and start exploring now.',
                                        textAlign: TextAlign.center,
                                        style: AppFonts.bodyStyle(
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
                                                style: AppFonts.bodyStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13 * scale,
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
                                                      style: AppFonts.titleStyle(
                                                        color: Colors.white,
                                                        fontSize: 18 * scale,
                                                        fontWeight: FontWeight.w700,
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
                                                    style: AppFonts.bodyStyle(
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
                                                style: AppFonts.bodyStyle(
                                                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                                                  fontSize: 14 * scale,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) =>  RegisterPage()),
                                                  );
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: Text(
                                                  'Create account',
                                                  style: AppFonts.bodyStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14 * scale,
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

                      // Skip Button (Relocated to be on top)
                      Positioned(
                        top: 50,
                        right: 16,
                        child: TextButton(
                          onPressed: () {
                            _authProvider?.skipLogin();
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          child: Text(
                            'Skip',
                            style: AppFonts.bodyStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16 * scale,
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
              style: AppFonts.bodyStyle(
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
      style: AppFonts.bodyStyle(
        color: AppColors.textPrimary,
        fontSize: 16 * scale,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppFonts.bodyStyle(
          color: AppColors.textDisabled,
          fontSize: 16 * scale,
          fontWeight: FontWeight.w500,
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
    return TweenAnimationBuilder(
      duration:  Duration(seconds: 3),
      tween: Tween<double>(begin: 0, end: 1),
      onEnd: () {}, // Not needed for simple loop
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 8 * (value > 0.5 ? (1 - value) * 2 : value * 2)),
          child: child,
        );
      },
      child: child,
    );
  }
}

class _GlowBubble extends StatefulWidget {
  const _GlowBubble({
    required this.size, 
    required this.color,
    this.shimmer = false,
  });

  final double size;
  final Color color;
  final bool shimmer;

  @override
  State<_GlowBubble> createState() => _GlowBubbleState();
}

class _GlowBubbleState extends State<_GlowBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _driftAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _driftAnimation = Tween<Offset>(
      begin: const Offset(-20, -20),
      end: const Offset(20, 20),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _driftAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: IgnorePointer(
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color,
                widget.color.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
