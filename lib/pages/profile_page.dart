import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';
import 'auth/login_page.dart';

/// Profile Screen - NeoTaste style
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final WalletService _walletService = WalletService();
  final AuthProvider _authProvider = AuthProvider();
  Wallet? _wallet;

  @override
  void initState() {
    super.initState();
    _authProvider.addListener(_onAuthStateChanged);
    _loadWallet();
    _refreshUserData();
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
    }
  }

  Future<void> _refreshUserData() async {
    if (_authProvider.isAuthenticated) {
      await _authProvider.refreshUser();
    }
  }

  Future<void> _loadWallet() async {
    if (!_authProvider.isAuthenticated || _authProvider.isMerchant) {
      return; // Don't load wallet for merchants
    }

    try {
      final wallet = await _walletService.getWallet();
      if (mounted) {
        setState(() {
          _wallet = wallet;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authProvider.user;
    final displayName = user?.username ?? 'Guest';
    final email = user?.email ?? '';
    final userId = user?.id ?? 0;
    final phoneNumber = user?.profile?.phoneNumber;
    final role = user?.profile?.role ?? 'customer';
    final isMerchant = user?.isMerchant ?? false;
    final isCustomer = user?.isCustomer ?? true;
    final initials = _getInitials(displayName);
    final isPremium = role == 'premium' || false;
    final accountType = isMerchant ? 'Merchant' : (isCustomer ? 'Customer' : 'Guest');

    return Scaffold(
      backgroundColor: NeoTasteColors.background,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: NeoTasteColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Circular Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: NeoTasteColors.accent,
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: NeoTasteColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Username
              Text(
                displayName,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NeoTasteColors.textPrimary,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: NeoTasteColors.textSecondary,
                  ),
                ),
              ],
              if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  phoneNumber,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: NeoTasteColors.textSecondary,
                  ),
                ),
              ],
              if (userId > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: NeoTasteColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID: $userId',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: NeoTasteColors.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              // Account Info Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Wallet Balance Card (if available and not merchant)
                    if (_wallet != null && !isMerchant) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: NeoTasteColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: NeoTasteColors.accent.withOpacity(0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: NeoTasteColors.accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: NeoTasteColors.accent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Wallet Balance',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: NeoTasteColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '£${_wallet!.balance}',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: NeoTasteColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Account Type Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: NeoTasteColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: NeoTasteColors.accent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: NeoTasteColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isMerchant ? Icons.store : Icons.person,
                              color: NeoTasteColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  accountType,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: NeoTasteColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Role: ${role.toUpperCase()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: NeoTasteColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subscription/Membership Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: NeoTasteColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPremium ? NeoTasteColors.accent : NeoTasteColors.textDisabled,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isPremium
                                  ? NeoTasteColors.accent
                                  : NeoTasteColors.textDisabled.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPremium ? Icons.star : Icons.star_border,
                              color: isPremium
                                  ? NeoTasteColors.primary
                                  : NeoTasteColors.textSecondary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPremium ? 'Premium Member' : 'Free Member',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: NeoTasteColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPremium
                                      ? 'Access to all exclusive deals'
                                      : 'Upgrade to unlock premium deals',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: NeoTasteColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isPremium)
                            TextButton(
                              onPressed: () {
                                // Navigate to upgrade
                              },
                              child: Text(
                                'Upgrade',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: NeoTasteColors.accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // List Items
              Container(
                color: NeoTasteColors.white,
                child: Column(
                  children: [
                    _buildListTile(
                      Icons.card_giftcard,
                      'Redeemed Deals',
                      'View your redeemed offers',
                      () {},
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      Icons.favorite,
                      'Favorites',
                      'Your saved restaurants',
                      () {},
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      Icons.help_outline,
                      'Help',
                      'Get support and FAQs',
                      () {},
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      Icons.logout,
                      'Logout',
                      'Sign out of your account',
                      () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: NeoTasteColors.white,
                            title: Text(
                              'Logout',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to logout?',
                              style: GoogleFonts.inter(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    color: NeoTasteColors.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: Text(
                                  'Logout',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true) {
                          await _authProvider.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          }
                        }
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.red
            : NeoTasteColors.textSecondary,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: isDestructive
              ? Colors.red
              : NeoTasteColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: NeoTasteColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: NeoTasteColors.textDisabled,
      ),
      onTap: onTap,
    );
  }
}
