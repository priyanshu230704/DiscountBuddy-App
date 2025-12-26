import 'package:flutter/material.dart';
import '../widgets/blurred_ellipse_background.dart';
import '../providers/auth_provider.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';
import 'auth/login_page.dart';

/// Profile/Settings page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// Local constants for profile page
class _ProfileConstants {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  static const double radiusMedium = 12.0;
}

class _ProfilePageState extends State<ProfilePage> {
  final WalletService _walletService = WalletService();
  Wallet? _wallet;
  bool _isLoadingWallet = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    if (!AuthProvider().isAuthenticated) {
      return;
    }

    setState(() {
      _isLoadingWallet = true;
    });

    try {
      final wallet = await _walletService.getWallet();
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _isLoadingWallet = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
        });
      }
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
    final user = AuthProvider().user;
    final displayName = user?.username ?? 'Guest';
    final email = user?.email ?? '';
    final initials = _getInitials(displayName);
    final walletBalance = _wallet?.balance ?? '0.00';
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Blurred ellipse at the top center background
          const BlurredEllipseBackground(),
          // Main content scrollable
          SafeArea(
            bottom: false,
            child: CustomScrollView(
        slivers: [
                // Custom Header
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      left: _ProfileConstants.paddingLarge,
                      right: _ProfileConstants.paddingLarge,
                      // bottom: _ProfileConstants.paddingLarge,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                        fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                      textAlign: TextAlign.center,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(_ProfileConstants.paddingXLarge),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF3E25F6),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: _ProfileConstants.paddingMedium),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: _ProfileConstants.paddingSmall),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      if (user?.profile?.role != null) ...[
                        const SizedBox(height: _ProfileConstants.paddingSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3E25F6).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF3E25F6),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            user!.profile!.role.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3E25F6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: _ProfileConstants.paddingMedium),
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _ProfileConstants.paddingMedium,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Wallet Balance',
                          _isLoadingWallet
                              ? 'Loading...'
                              : '£$walletBalance',
                          Icons.account_balance_wallet,
                          const Color(0xFF3E25F6),
                        ),
                      ),
                      const SizedBox(width: _ProfileConstants.paddingMedium),
                      Expanded(
                        child: _buildStatCard(
                          'Account Type',
                          user?.isMerchant == true
                              ? 'Merchant'
                              : user?.isCustomer == true
                                  ? 'Customer'
                                  : 'Guest',
                          user?.isMerchant == true
                              ? Icons.store
                              : Icons.person,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _ProfileConstants.paddingLarge),
                // Settings List
                Container(
                  color: const Color(0xFF1E1E1E),
                  child: Column(
                    children: [
                      _buildListTile(
                        Icons.card_membership,
                        'My Membership',
                        'View membership details',
                        () {},
                      ),
                      Divider(height: 1, color: Colors.grey[800]),
                      _buildListTile(
                        Icons.history,
                        'Visit History',
                        'View your restaurant visits',
                        () {},
                      ),
                      Divider(height: 1, color: Colors.grey[800]),
                      _buildListTile(
                        Icons.favorite,
                        'Favorites',
                        'Your saved restaurants',
                        () {},
                      ),
                      Divider(height: 1, color: Colors.grey[800]),
                      _buildListTile(
                        Icons.notifications,
                        'Notifications',
                        'Manage notifications',
                        () {},
                      ),
                      Divider(height: 1, color: Colors.grey[800]),
                      _buildListTile(
                        Icons.settings,
                        'Settings',
                        'App settings and preferences',
                        () {},
                      ),
                      Divider(height: 1, color: Colors.grey[800]),
                      _buildListTile(
                        Icons.help_outline,
                        'Help & Support',
                        'Get help and contact support',
                        () {},
                      ),
                      Divider(height: 1, color: Colors.grey[800]),
                      _buildListTile(
                        Icons.info_outline,
                        'About',
                        'App version and information',
                        () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _ProfileConstants.paddingLarge),
                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _ProfileConstants.paddingMedium,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        // Show confirmation dialog
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            title: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'Are you sure you want to logout?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true) {
                          // Perform logout using auth provider
                          await AuthProvider().logout();
                          
                          // Navigate to login page
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          vertical: _ProfileConstants.paddingMedium,
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ),
                const SizedBox(height: _ProfileConstants.paddingLarge),
              ],
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(_ProfileConstants.paddingLarge),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(_ProfileConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: _ProfileConstants.paddingSmall),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[400]),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

