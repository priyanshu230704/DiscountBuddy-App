import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'login_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Register Screen - Redesigned
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _isFormValid = false;
  String _selectedRole = 'customer'; // 'customer' or 'merchant'

  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_authListener);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
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
    final isValid =
        _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.length >= 4 &&
        _confirmPasswordController.text == _passwordController.text &&
        _agreeToTerms &&
        _selectedRole.isNotEmpty;
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
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && controller.text == currentText) {
          controller.value = controller.value.copyWith(
            text: sanitizedText,
            selection: TextSelection.collapsed(offset: sanitizedText.length),
          );
        }
      });
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate() && _authProvider != null) {
      await _authProvider!.register(
        email: _emailController.text.trim(),
        username: _nameController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
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
            // Removed NeverScrollableScrollPhysics to allow scrolling on smaller screens
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    'Create your account',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle
                  Text(
                    'Unlock exclusive restaurant offers',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Full Name Input
                  AuthTextField(
                    controller: _nameController,
                    placeholder: 'Full Name',
                    focusNode: _nameFocusNode,
                    onChanged: (value) {
                      _sanitizeField(
                        _nameController,
                        RegExp(r'[a-zA-Z\s]'),
                        maxLength: 20,
                      );
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.length > 20) {
                        return 'Name cannot exceed 20 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z\s]*$').hasMatch(value)) {
                        return 'Only letters and spaces are allowed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Email / Mobile Input
                  AuthTextField(
                    controller: _emailController,
                    placeholder: 'Email / Mobile',
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
                        return 'Please enter your email or mobile';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9.@]*$').hasMatch(value)) {
                        return 'Only letters, numbers, . and @ are allowed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Password Input
                  AuthTextField(
                    controller: _passwordController,
                    placeholder: 'Password',
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
                      if (value.length < 4) {
                        return 'Password must be at least 4 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

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
                  const SizedBox(height: AppSpacing.lg),

                  // Role Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Type',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard(
                                value: 'customer',
                                icon: Icons.person,
                                label: 'Customer',
                                theme: theme,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildRoleCard(
                                value: 'merchant',
                                icon: Icons.store,
                                label: 'Merchant',
                                theme: theme,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Terms Checkbox
                  Row(
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
                          decoration: BoxDecoration(
                            color: _agreeToTerms
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: _agreeToTerms
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _agreeToTerms
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreeToTerms = !_agreeToTerms;
                              _validateForm();
                            });
                          },
                          child: Text(
                            'I agree to Terms & Privacy Policy',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Create Account Button
                  AuthButton(
                    text: 'Create Account',
                    onPressed: _isFormValid && !_isLoading
                        ? _handleRegister
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
                        const Text(
                          'G',
                          style: TextStyle(
                            color: Colors.blue,
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
                        'Already have an account?',
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
                                      const LoginPage(),
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
                          'Log in',
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

  Widget _buildRoleCard({
    required String value,
    required IconData icon,
    required String label,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
          _validateForm();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
