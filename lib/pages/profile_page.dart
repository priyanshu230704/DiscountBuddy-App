import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';
import 'edit_profile_page.dart';

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

  Future<void> _loadWallet() async {
    if (!_authProvider.isAuthenticated || _authProvider.isMerchant) {
      return;
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
      return parts[0][0].toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authProvider.user;
    final displayName = user?.username ?? 'Guest';
    final initials = _getInitials(displayName);
    final walletBalance = _wallet?.balance ?? '0.00';

    return Scaffold(
      backgroundColor: NeoTasteColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Profile title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'Profile',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: NeoTasteColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User Profile Section with Edit Profile
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      // Avatar with green background
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: NeoTasteColors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and Edit profile
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: NeoTasteColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Edit profile',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: NeoTasteColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: NeoTasteColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Cards Row
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _StatCard(
                      icon: Icons.favorite,
                      value: '0',
                      label: 'Favourites',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.account_balance_wallet,
                      value: '£$walletBalance',
                      label: 'Saved',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.local_offer,
                      value: '0',
                      label: 'Deals',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(icon: Icons.star, value: '1', label: 'Loyalty'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Invitation Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32), // Dark green
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earn €10 for every friend you invite!',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: NeoTasteColors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle invite friends
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            foregroundColor: NeoTasteColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Invite friends',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Navigation List Items
              Container(
                color: NeoTasteColors.white,
                child: Column(
                  children: [
                    _buildListTile(Icons.card_membership, 'Membership', () {
                      // Navigate to membership
                    }),
                    const Divider(height: 1),
                    _buildListTile(Icons.help_outline, 'Help & Support', () {
                      // Navigate to help
                    }),
                    const Divider(height: 1),
                    _buildListTile(Icons.settings, 'Settings', () {
                      // Navigate to settings
                    }),
                    const Divider(height: 1),
                    _buildListTile(Icons.logout, 'Logout', () {
                      _showLogoutConfirmation();
                    }, isDestructive: true),
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

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: NeoTasteColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : NeoTasteColors.textPrimary,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : NeoTasteColors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? Colors.red : NeoTasteColors.textPrimary,
      ),
      onTap: onTap,
    );
  }
}

/// Statistics Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NeoTasteColors.textDisabled.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: NeoTasteColors.textPrimary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: NeoTasteColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: NeoTasteColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
