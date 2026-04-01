import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../widgets/app_scaffold.dart';
import '../providers/auth_provider.dart';
import '../services/wallet_service.dart';
import '../services/restaurant_service.dart';
import '../models/user_interactions.dart';
import 'edit_profile_page.dart';
import 'help_support_page.dart';
import 'privacy_policy_page.dart';
import 'saved_restaurants_page.dart';
import 'savings_history_page.dart';
import 'join_partner_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/environment.dart';

/// Profile Screen - NeoTaste style
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
    if (!_authProvider.isAuthenticated || _authProvider.isMerchant) {
      return;
    }

    try {
      await _walletService.getWallet();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadStats() async {
    if (!_authProvider.isAuthenticated || _authProvider.isMerchant) {
      return;
    }

    try {
      final stats = await _restaurantService.getProfileStats();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = _authProvider.user;
    final displayName = user?.username ?? 'User';

    return AppScaffold(
        body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
                child: Text(
                  'Profile',
                  style: AppTypography.headline.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(color: AppColors.cardBorder, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Builder(
                          builder: (context) {
                            final profilePic = user?.profilePicture;
                            if (profilePic == null) {
                              return Center(
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.textDisabled.withValues(alpha: 0.5),
                                ),
                              );
                            }
                            
                            return ClipOval(
                              child: profilePic.startsWith('assets/')
                                  ? Image.asset(profilePic, fit: BoxFit.cover)
                                  : (profilePic.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: profilePic.startsWith('http') 
                                              ? profilePic 
                                              : '${Environment.baseUrl}$profilePic',
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.person,
                                            size: 40,
                                            color: AppColors.textDisabled.withValues(alpha: 0.5),
                                          ),
                                        )),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTypography.title.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Edit profile',
                              style: AppTypography.body.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Stats Grid
              if (!_authProvider.isMerchant) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.emoji_events,
                          value: _stats?.userLevel ?? 'Bronze',
                          label: 'Level',
                          iconColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SavingsHistoryPage(),
                              ),
                            );
                          },
                          child: _StatCard(
                            icon: Icons.account_balance_wallet_rounded,
                            value: '£${_stats?.moneySaved.toStringAsFixed(0) ?? '5'}',
                            label: 'Saved',
                            iconColor: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SavedRestaurantsPage(),
                              ),
                            );
                          },
                          child: _StatCard(
                            icon: Icons.favorite,
                            value: _stats?.favouriteRestaurants.toString() ?? '2',
                            label: 'Favourites',
                            iconColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Menu Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportPage(),
                          ),
                        );
                      },
                    ),
                    if (!_authProvider.isMerchant) ...[
                      const SizedBox(height: 16),
                      _MenuTile(
                        icon: Icons.storefront_outlined,
                        title: 'Join as restaurant partner',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JoinPartnerPage(),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    _MenuTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _MenuTile(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      isDestructive: false,
                      onTap: () {
                        _showLogoutConfirmation();
                      },
                    ),
                    const SizedBox(height: 16),
                    _MenuTile(
                      icon: Icons.delete_forever_rounded,
                      title: 'Delete Account',
                      isDestructive: true,
                      onTap: () {
                        _showDeleteAccountConfirmation();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Text(
                    'powered by Markitup Group Ltd.',
                    style: AppTypography.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDisabled,
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

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xLarge),
        title: Text(
          'Logout',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authProvider.logout();
              if (context.mounted) {
                // Use rootNavigator: true to ensure we pop everything and go to login
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: Text(
              'Logout',
              style: AppTypography.body.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xLarge),
        title: Text(
          'Delete Account',
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.error,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone.',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'A verification code will be sent to your email to confirm this action.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _initDeleteAccount();
            },
            child: Text(
              'Send Code',
              style: AppTypography.body.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initDeleteAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await _authProvider.deleteAccountInit();
      if (mounted) {
        Navigator.pop(context); // Close loading
        if (success) {
          _showOtpVerificationDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_authProvider.errorMessage ?? 'Failed to send verification code')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showOtpVerificationDialog() {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xLarge),
        title: Text(
          'Verify Deletion',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the 4-digit code sent to your email to permanently delete your account.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '0000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final otp = otpController.text.trim();
              if (otp.length == 4) {
                Navigator.pop(context);
                _performDeleteAccount(otp);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a 4-digit code')),
                );
              }
            },
            child: Text(
              'Delete Account',
              style: AppTypography.body.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount(String otp) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await _authProvider.deleteAccount(otp: otp);
      if (success && mounted) {
        Navigator.pop(context); // Close loading
        // Use rootNavigator: true to ensure we pop everything and go to login
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
      } else if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_authProvider.errorMessage ?? 'Failed to delete account')),
        );
        // Reshow OTP dialog if verification failed
        _showOtpVerificationDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${e.toString()}')),
        );
      }
    }
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl - 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xLarge,
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? AppColors.error
                  : AppColors.textPrimary,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDestructive
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.textDisabled,
              size: 20,
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
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xLarge,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.title.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
