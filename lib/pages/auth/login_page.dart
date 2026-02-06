import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'register_page.dart';

/// Login Screen - Redesigned
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
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // App Branding (Placeholder for Icon/Logo)
                  Center(
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.percent,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Large Heading
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Small Subtitle
                  Text(
                    'Log in to continue discovering deals',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Email / Mobile Input
                  AuthTextField(
                    controller: _emailController,
                    placeholder: 'Email / Mobile',
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocusNode,
                    autovalidateMode: AutovalidateMode.disabled,
                    validator: null,
                  ),
                  const SizedBox(height: AppSpacing.md),

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
                  const SizedBox(height: AppSpacing.sm),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      child: Text(
                        'Forgot password?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Login Button
                  AuthButton(
                    text: 'Login',
                    onPressed: _isFormValid && !_isLoading
                        ? _handleLogin
                        : null,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Google Login Button
                  OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      backgroundColor: theme.cardTheme.color,
                      foregroundColor: theme.textTheme.bodyLarge?.color,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'G',
                          style: TextStyle(
                            color: Colors.blue, // Google Blue
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New here?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
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
