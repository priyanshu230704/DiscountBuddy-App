import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_theme.dart';
import 'register_page.dart';

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
            backgroundColor: Colors.orange,
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
          backgroundColor: Colors.orange,
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
          backgroundColor: Colors.green,
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
      canPop: false,
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
            
            // Decorative Glow Bubbles (Mesh effect)
            if (!isKeyboardOpen) ...[
              Positioned(
                top: -100,
                right: -50,
                child: _GlowBubble(size: 450, color:  Color(0xFFDCCBFF).withValues(alpha: 0.5)),
              ),
              Positioned(
                bottom: -80,
                left: -60,
                child: _GlowBubble(size: 500, color:  Color(0xFFFFD6E7).withValues(alpha: 0.4)),
              ),
            ],

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
                      // Floating 3D Icons
                      if (!isKeyboardOpen) ...[
                        Positioned(
                          top: 240 * scale,
                          left: -10 * scale,
                          child: Opacity(
                            opacity: 0.5,
                            child: _AnimatedIcon(
                              child: Image.asset('assets/png/sushi_icon.png', width: 64 * scale),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 340 * scale,
                          right: -10 * scale,
                          child: Opacity(
                            opacity: 0.4,
                            child: Image.asset('assets/png/burger_icon.png', width: 72 * scale),
                          ),
                        ),
                        Positioned(
                          top: 150 * scale,
                          right: 20 * scale,
                          child: Opacity(
                            opacity: 0.6,
                            child: Transform.rotate(
                              angle: -0.2,
                              child: Image.asset('assets/png/discount_tag_icon.png', width: 48 * scale),
                            ),
                          ),
                        ),
                      ],
                      
                      SafeArea(
                        key:  ValueKey('login_safe_area'),
                        child: Form(
                          key: _formKey,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                 Spacer(flex: 3),
                                
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
                                              color:  Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                              blurRadius: 25,
                                              offset:  Offset(0, 6),
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
                                      style: GoogleFonts.outfit(
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
                                        style: GoogleFonts.plusJakartaSans(
                                          color:  Color(0xFF5F567A).withValues(alpha: 0.8),
                                          fontSize: 16 * scale,
                                          height: 1.3,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                
                                 Spacer(flex: 2),
                                
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
                                            color:  Color(0xFF2E1A47).withValues(alpha: 0.08),
                                            blurRadius: 40,
                                            offset:  Offset(0, 15),
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
                                                color:  Color(0xFF9A8FB7),
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
                                                style: GoogleFonts.plusJakartaSans(
                                                  color:  Color(0xFF8B5CF6),
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
                                              gradient:  LinearGradient(
                                                colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius: BorderRadius.circular(18 * scale),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:  Color(0xFF8B5CF6).withValues(alpha: 0.25),
                                                  blurRadius: 15,
                                                  offset:  Offset(0, 6),
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
                                                      child:  CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                    )
                                                  : Text(
                                                      'Log In',
                                                      style: GoogleFonts.outfit(
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
                                              Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.1))),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                child: Text(
                                                  'OR',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    color:  Color(0xFFA7A0BB),
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12 * scale,
                                                  ),
                                                ),
                                              ),
                                              Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.1))),
                                            ],
                                          ),
                                          SizedBox(height: (isKeyboardOpen ? 18 : 24) * scale),
                                          OutlinedButton(
                                            onPressed: _isLoading ? null : _handleGoogleLogin,
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: Size(double.infinity, (isKeyboardOpen ? 48 : 56) * scale),
                                              side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16 * scale),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.network(
                                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                                  height: 18 * scale,
                                                ),
                                                 SizedBox(width: 10),
                                                Text(
                                                  'Continue with Google',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    color:  Color(0xFF1D1930),
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14 * scale,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 18 * scale),
                                          // NEW HERE? CREATE ACCOUNT
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'New here?',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color:  Color(0xFF5F567A).withValues(alpha: 0.7),
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
                                                  style: GoogleFonts.plusJakartaSans(
                                                    color:  Color(0xFF8B5CF6),
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
                                
                                 Spacer(flex: 3),
                                
                                if (!isKeyboardOpen) ...[
                                  // Trending Deal Banner
                                  Container(
                                    margin: EdgeInsets.only(bottom: 12 * scale),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(24 * scale),
                                      border: Border.all(color: Colors.white),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                             Text('🔥', style: TextStyle(fontSize: 13)),
                                             SizedBox(width: 6),
                                            Text(
                                              'Trending Deal Today',
                                              style: GoogleFonts.outfit(
                                                color:  Color(0xFF3A2F55),
                                                fontSize: 13 * scale,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                         SizedBox(height: 2),
                                        Text(
                                          '50% off sushi near you',
                                          style: GoogleFonts.plusJakartaSans(
                                            color:  Color(0xFF2C2343),
                                            fontSize: 15 * scale,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                 Spacer(flex: 2),
                              ],
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
      style: GoogleFonts.plusJakartaSans(
        color:  Color(0xFF2E2648),
        fontSize: 16 * scale,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(
          color:  Color(0xFF9C94B2),
          fontSize: 16 * scale,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor:  Color(0xFFF7F7FD),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18 * scale,
          vertical: (isSmall ? 14 : 16) * scale,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide: BorderSide(color:  Color(0xFF8B5CF6).withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide: BorderSide(color:  Color(0xFF8B5CF6).withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide:  BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
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

class _GlowBubble extends StatelessWidget {
  const _GlowBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
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
    );
  }
}
