import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_theme.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'register_page.dart';

/// Login Screen - NeoTaste style
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
      await _authProvider!.loginWithGoogle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AuthTheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Back Arrow
                  const SizedBox(height: 40),

                  // Large Heading
                  Text('Welcome back', style: AuthTheme.headingLarge),
                  const SizedBox(height: 8),

                  // Small Subtitle
                  Text(
                    'Log in to continue discovering deals',
                    style: AuthTheme.subtitle,
                  ),
                  const SizedBox(height: 48),

                  // Email / Mobile Input
                  AuthTextField(
                    controller: _emailController,
                    placeholder: 'Email / Mobile',
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocusNode,
                    autovalidateMode: AutovalidateMode.disabled,
                    validator: null,
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  AuthTextField(
                    controller: _passwordController,
                    placeholder: 'Password',
                    obscureText: _obscurePassword,
                    showToggle: true,
                    focusNode: _passwordFocusNode,
                    autovalidateMode: AutovalidateMode.disabled,
                    onToggleVisibility: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: null,
                  ),
                  const SizedBox(height: 12),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      child: Text(
                        'Forgot password?',
                        style: AuthTheme.linkText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  AuthButton(
                    text: 'Login',
                    onPressed: _isFormValid && !_isLoading
                        ? _handleLogin
                        : null,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey.withOpacity(0.3)),
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
                        child: Divider(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
                        // Google Logo (simulated with text if asset missing, but standard is icon)
                        // Using a simple 'G' styled text as fallback or just the text "Continue with Google"
                        Text(
                          'G',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto', // Google font usually
                          ),
                        ),
                        const SizedBox(width: 12),
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
                  const SizedBox(height: 24),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('New here?', style: AuthTheme.subtitle),
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
                                      const RegisterPage(),
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
                                            begin: const Offset(1.0, 0.0),
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
                        child: Text(
                          'Create account',
                          style: AuthTheme.linkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
