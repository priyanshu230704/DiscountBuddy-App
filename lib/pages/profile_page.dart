import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/wallet_service.dart';
import '../services/restaurant_service.dart';
import '../models/user_interactions.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'edit_profile_page.dart';
import 'help_support_page.dart';
import 'privacy_policy_page.dart';

/// Profile Screen - Redesigned
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final WalletService _walletService = WalletService();
  final RestaurantService _restaurantService = RestaurantService();
  final AuthProvider _authProvider = AuthProvider();
  ProfileStats? _stats;

  @override
  void initState() {
    super.initState();
    _authProvider.addListener(_onAuthStateChanged);
    _authProvider.refreshUser();
    _loadWallet();
    _loadStats();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
      _loadWallet();
      _loadStats();
    }
  }

  Future<void> _loadWallet() async {
    if (!_authProvider.isAuthenticated || _authProvider.isMerchant) return;
    try {
      await _walletService.getWallet();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    if (!_authProvider.isAuthenticated || _authProvider.isMerchant) return;
    try {
      final stats = await _restaurantService.getProfileStats();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (_) {}
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authProvider.user;
    final displayName = user?.username ?? 'Guest';
    final initials = _getInitials(displayName);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Profile', style: theme.textTheme.headlineSmall),
                    IconButton(
                      onPressed: () {
                        final themeProvider = Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        );
                        themeProvider.toggleTheme();
                      },
                      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // User Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Edit profile',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.iconTheme.color),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Stats Cards
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  children: [
                    _StatCard(
                      icon: Icons.favorite,
                      value: _stats?.favouriteRestaurants.toString() ?? '0',
                      label: 'Favourites',
                      color: Colors.pink,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StatCard(
                      icon: Icons.account_balance_wallet,
                      value: '£${_stats?.moneySaved.toStringAsFixed(0) ?? '0'}',
                      label: 'Saved',
                      color: Colors.green,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StatCard(
                      icon: Icons.local_offer,
                      value: _stats?.dealsClaimed.toString() ?? '0',
                      label: 'Deals',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StatCard(
                      icon: Icons.star,
                      value: _stats?.userLevel ?? 'Bronze',
                      label: 'Level',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Navigation List Items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MenuTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MenuTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      isDestructive: true,
                      onTap: () => _showLogoutConfirmation(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: Text('Logout', style: theme.textTheme.titleLarge),
        content: Text(
          'Are you sure you want to logout?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authProvider.logout();
              if (mounted) Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDestructive ? Colors.red : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive
                  ? Colors.red.withOpacity(0.5)
                  : theme.iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
