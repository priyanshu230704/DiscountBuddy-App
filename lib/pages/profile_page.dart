import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'level_progress_page.dart';
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

  void _navigateToLevelDetails() {
    if (_stats == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelProgressPage(stats: _stats!),
      ),
    );
  }


  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfilePage(),
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final items = <_ProfileMenuItem>[
      _ProfileMenuItem(
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
      if (!_authProvider.isMerchant)
        _ProfileMenuItem(
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
      _ProfileMenuItem(
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
      _ProfileMenuItem(
        icon: Icons.logout_rounded,
        title: 'Logout',
        onTap: _showLogoutConfirmation,
      ),
      _ProfileMenuItem(
        icon: Icons.delete_forever_rounded,
        title: 'Delete Account',
        isDestructive: true,
        onTap: _showDeleteAccountConfirmation,
      ),
    ];

    return [
      for (var i = 0; i < items.length; i++) ...[
        _MenuTile(
          icon: items[i].icon,
          title: items[i].title,
          isDestructive: items[i].isDestructive,
          onTap: items[i].onTap,
        ),
        if (i < items.length - 1)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            endIndent: AppSpacing.lg,
            color: AppColors.divider,
          ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = _authProvider.user;
    final displayName = user?.username ?? 'User';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: AppScaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(
                displayName: displayName,
                profilePicture: user?.profilePicture,
                stats: _stats,
                showStats: !_authProvider.isMerchant,
                isLoadingStats: !_authProvider.isMerchant && _stats == null,
                onEditProfile: _navigateToEditProfile,
                onLevelTap: _navigateToLevelDetails,
                onSavingsTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavingsHistoryPage(),
                    ),
                  );
                },
                onFavouritesTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedRestaurantsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Menu Options
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.xLarge,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: _buildMenuItems(),
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
                      fontWeight: FontWeight.w500,
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
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w600),
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
            fontWeight: FontWeight.w600,
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
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w600),
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

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String? profilePicture;
  final ProfileStats? stats;
  final bool showStats;
  final bool isLoadingStats;
  final VoidCallback onEditProfile;
  final VoidCallback onLevelTap;
  final VoidCallback onSavingsTap;
  final VoidCallback onFavouritesTap;

  const _ProfileHeader({
    required this.displayName,
    required this.profilePicture,
    required this.stats,
    required this.showStats,
    required this.isLoadingStats,
    required this.onEditProfile,
    required this.onLevelTap,
    required this.onSavingsTap,
    required this.onFavouritesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child: _buildAvatar()),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      displayName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTypography.title.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  if (showStats) ...[
                    const SizedBox(height: AppSpacing.xl),
                    if (isLoadingStats)
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _HeaderStatItem(
                              value: stats?.progression.tier ?? 'Bronze',
                              label: stats?.progression.rank ?? 'Level',
                              onTap: stats == null ? null : onLevelTap,
                            ),
                          ),
                          _headerDivider(),
                          Expanded(
                            child: _HeaderStatItem(
                              value: '£${stats?.moneySaved.toStringAsFixed(0) ?? '0'}',
                              label: 'Savings',
                              onTap: onSavingsTap,
                            ),
                          ),
                          _headerDivider(),
                          Expanded(
                            child: _HeaderStatItem(
                              value: stats?.favouriteRestaurants.toString() ?? '0',
                              label: 'Favourites',
                              onTap: onFavouritesTap,
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: IconButton(
                onPressed: onEditProfile,
                tooltip: 'Edit profile',
                icon: SvgPicture.asset(
                  'assets/svg/edit.svg',
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildAvatarImage(profilePicture),
      ),
    );
  }

  Widget _headerDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.white.withValues(alpha: 0.25),
    );
  }

  Widget _buildAvatarImage(String? profilePic) {
    if (profilePic == null || profilePic.isEmpty) {
      return Center(
        child: Icon(
          Icons.person,
          size: 44,
          color: AppColors.textDisabled.withValues(alpha: 0.5),
        ),
      );
    }

    if (profilePic.startsWith('assets/')) {
      return Image.asset(profilePic, fit: BoxFit.cover);
    }

    return CachedNetworkImage(
      imageUrl: profilePic.startsWith('http')
          ? profilePic
          : '${Environment.baseUrl}$profilePic',
      fit: BoxFit.cover,
    );
  }
}

class _HeaderStatItem extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _HeaderStatItem({
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.title.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });
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
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
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
      ),
    );
  }
}
