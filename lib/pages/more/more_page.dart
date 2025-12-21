import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/blurred_ellipse_background.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/voucher_service.dart';
import '../../models/voucher.dart';
import '../profile_page.dart';
import '../auth/login_page.dart';

/// More/Settings page
class MorePage extends StatefulWidget {
  final ThemeProvider? themeProvider;
  
  const MorePage({super.key, this.themeProvider});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final VoucherService _voucherService = VoucherService();
  List<Voucher> _vouchers = [];
  bool _isLoadingVouchers = false;
  int _voucherCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserVouchers();
  }

  Future<void> _loadUserVouchers() async {
    // Only load vouchers if user is authenticated
    final authProvider = AuthProvider();
    if (!authProvider.isAuthenticated) {
      return;
    }

    // Try to load vouchers even if not a merchant (API will return error for non-merchants)
    setState(() {
      _isLoadingVouchers = true;
    });

    try {
      final response = await _voucherService.getUserVouchers();
      if (mounted) {
        setState(() {
          _vouchers = response.results;
          _voucherCount = response.count;
          _isLoadingVouchers = false;
        });
      }
    } catch (e) {
      // If error (e.g., user is not a merchant), just set empty list
      if (mounted) {
        setState(() {
          _vouchers = [];
          _voucherCount = 0;
          _isLoadingVouchers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Blurred ellipse at the top center background
          const BlurredEllipseBackground(),
          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom AppBar
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    left: AppConstants.paddingMedium,
                    right: AppConstants.paddingMedium,
                    bottom: AppConstants.paddingMedium,
                  ),
                  child: const Text(
                    'More',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Content list
                Expanded(
                  child: ListView(
                    children: [
                      // Profile Section
                      _buildProfileSection(),
                      const SizedBox(height: AppConstants.paddingMedium),
                      // My Vouchers Section (show for all authenticated users, but content varies)
                      if (AuthProvider().isAuthenticated) _buildVouchersSection(),
                      if (AuthProvider().isAuthenticated)
                        const SizedBox(height: AppConstants.paddingMedium),
                      // Account Section
                      _buildSection(
                        'Account',
                        [
                          _buildListTile(
                            Icons.person,
                            'Edit Profile',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfilePage(),
                                ),
                              );
                            },
                          ),
                          _buildListTile(
                            Icons.card_membership,
                            'My Membership',
                            () {},
                          ),
                          _buildListTile(
                            Icons.payment,
                            'Payment Methods',
                            () {},
                          ),
                          _buildListTile(
                            Icons.history,
                            'Visit History',
                            () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      // Preferences Section
                      _buildSection(
                        'Preferences',
                        [
                          _buildListTile(
                            Icons.notifications,
                            'Notifications',
                            () {},
                          ),
                          _buildListTile(
                            Icons.location_on,
                            'Location Settings',
                            () {},
                          ),
                          _buildListTile(
                            Icons.language,
                            'Language',
                            () {},
                          ),
                          // Theme Toggle
                          _buildThemeTile(
                            widget.themeProvider?.isDarkMode == true
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            'Theme',
                            widget.themeProvider?.isDarkMode == true
                                ? 'Dark Mode'
                                : 'Light Mode',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      // Support Section
                      _buildSection(
                        'Support & Feedback',
                        [
                          _buildSupportItem(
                            Icons.feedback_outlined,
                            'Send Feedback',
                            'Share your feedback with us',
                            () {},
                          ),
                          _buildSupportItem(
                            Icons.help_outline,
                            'Help Center',
                            'Get help and support',
                            () {},
                          ),
                          _buildSupportItem(
                            Icons.contact_support,
                            'Contact Us',
                            'Visit our website or email us',
                            () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      // About Section
                      _buildSection(
                        'About',
                        [
                          _buildAboutItem(
                            Icons.info_outline,
                            'About DiscountBuddy',
                            'Learn more about the app',
                            () {},
                          ),
                          _buildAboutItem(
                            Icons.privacy_tip,
                            'Privacy Policy',
                            'How we protect your data',
                            () {},
                          ),
                          _buildAboutItem(
                            Icons.description,
                            'Terms & Conditions',
                            'App usage terms',
                            () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      // Logout
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMedium,
                        ),
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
                              vertical: AppConstants.paddingMedium,
                            ),
                          ),
                          child: const Text('Logout'),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
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

  Widget _buildSupportItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2B2D30),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.orange,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2B2D30),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.green,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVouchersSection() {
    final user = AuthProvider().user;
    final isMerchant = user?.isMerchant ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppConstants.paddingMedium,
            right: AppConstants.paddingMedium,
            bottom: AppConstants.paddingSmall,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Vouchers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_isLoadingVouchers && _voucherCount > 0)
                Text(
                  '$_voucherCount vouchers',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        if (!isMerchant)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B1F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2B2D30),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'Vouchers are only available for merchants',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else if (_isLoadingVouchers)
          const Padding(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_vouchers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B1F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2B2D30),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'No vouchers yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
            ),
            child: Column(
              children: _vouchers.take(5).map((voucher) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B1F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2B2D30),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  voucher.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  voucher.code,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: voucher.isActive
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              voucher.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: voucher.isActive
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.percent,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${voucher.discountPercent.toStringAsFixed(0)}% OFF',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.people,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${voucher.soldQuantity}/${voucher.totalQuantity} sold',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileSection() {
    final user = AuthProvider().user;
    final displayName = user?.username ?? 'Guest';
    final email = user?.email ?? '';
    final initials = _getInitials(displayName);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF3E25F6),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
          ),
        ],
      ),
    );
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppConstants.paddingMedium,
            right: AppConstants.paddingMedium,
            bottom: AppConstants.paddingSmall,
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2B2D30),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3E25F6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3E25F6),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(IconData icon, String title, String subtitle) {
    if (widget.themeProvider == null) return const SizedBox.shrink();
    
    return InkWell(
      onTap: () {
        widget.themeProvider!.toggleTheme();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2B2D30),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.orange,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: widget.themeProvider!.isDarkMode,
              onChanged: (value) {
                widget.themeProvider!.setTheme(value);
              },
              activeTrackColor: const Color(0xFF3E25F6),
            ),
          ],
        ),
      ),
    );
  }
}

