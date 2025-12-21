import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/blurred_ellipse_background.dart';
import '../../providers/theme_provider.dart';
import '../profile_page.dart';

/// More/Settings page
class MorePage extends StatelessWidget {
  final ThemeProvider? themeProvider;
  
  const MorePage({super.key, this.themeProvider});

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
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        color: const Color(0xFF1E1E1E),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFF3E25F6),
                              child: const Text(
                                'JD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppConstants.paddingMedium),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'John Doe',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'john@example.com',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
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
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      // Account Section
                      _buildSection(
                        'Account',
                        [
                          _buildListTile(
                            Icons.person,
                            'Edit Profile',
                            () {},
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
                            themeProvider?.isDarkMode == true
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            'Theme',
                            themeProvider?.isDarkMode == true
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
                          onPressed: () {
                            // Handle logout
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
    if (themeProvider == null) return const SizedBox.shrink();
    
    return InkWell(
      onTap: () {
        themeProvider!.toggleTheme();
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
              value: themeProvider!.isDarkMode,
              onChanged: (value) {
                themeProvider!.setTheme(value);
              },
              activeTrackColor: const Color(0xFF3E25F6),
            ),
          ],
        ),
      ),
    );
  }
}

