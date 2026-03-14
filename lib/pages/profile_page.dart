import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/wallet_service.dart';
import '../services/restaurant_service.dart';
import '../models/user_interactions.dart';
import 'edit_profile_page.dart';
import 'help_support_page.dart';
import 'privacy_policy_page.dart';

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
    final displayName = user?.username ?? 'chavdaa';
    final initials = _getInitials(displayName);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text(
                  'Profile',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B1436),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // User Info Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4F46E5),
                              Color(0xFF6366F1),
                            ], // Deep Blue/Purple for Avatar
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4F46E5,
                              ).withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1436),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Edit profile',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF1B1436),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Stats Grid
              if (!_authProvider.isMerchant) ...[
                SizedBox(
                  height: 135,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      SizedBox(
                        width: 120,
                        child: _StatCard(
                          icon: Icons.emoji_events,
                          value: _stats?.userLevel ?? 'Bronze',
                          label: 'Level',
                          iconColor: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: _StatCard(
                          icon: Icons.account_balance_wallet_rounded,
                          value: '£${_stats?.moneySaved.toStringAsFixed(0) ?? '5'}',
                          label: 'Saved',
                          iconColor: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: _StatCard(
                          icon: Icons.favorite,
                          value: _stats?.favouriteRestaurants.toString() ?? '2',
                          label: 'Favourites',
                          iconColor: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: _StatCard(
                          icon: Icons.local_offer,
                          value: _stats?.dealsClaimed.toString() ?? '2',
                          label: 'Deals',
                          iconColor: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Invite Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 165,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      image: const DecorationImage(
                        image: AssetImage("assets/png/invite_full_bg.png"),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFC026D3,
                          ).withValues(alpha: 0.35),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 24, 24),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Earn €10 for every\nfriend you invite!',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.15,
                                    letterSpacing: -0.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Invite friends',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(flex: 4),
                        ],
                      ),
                    ),
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
                      isDestructive: true,
                      onTap: () {
                        _showLogoutConfirmation();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 120),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w800,
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF1B1436),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDestructive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF1B1436),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive
                  ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                  : const Color(0xFFD1D5DB),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1436),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
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
