import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../widgets/blurred_ellipse_background.dart';

/// Profile/Settings page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User _user = User(
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
    membership: Membership(
      membershipId: 'MEM123456',
      tier: 'premium',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      expiryDate: DateTime.now().add(const Duration(days: 335)),
      status: 'active',
    ),
    totalSavings: 245.50,
    restaurantsVisited: 12,
  );

  @override
  Widget build(BuildContext context) {
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
                      top: MediaQuery.of(context).padding.top + AppConstants.paddingMedium,
                      left: AppConstants.paddingLarge,
                      right: AppConstants.paddingLarge,
                      bottom: AppConstants.paddingLarge,
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
                  padding: const EdgeInsets.all(AppConstants.paddingXLarge),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF3E25F6),
                        child: Text(
                          _user.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Text(
                        _user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        _user.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Savings',
                          '£${_user.totalSavings.toStringAsFixed(2)}',
                          Icons.savings,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildStatCard(
                          'Restaurants',
                          '${_user.restaurantsVisited}',
                          Icons.restaurant,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
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
                const SizedBox(height: AppConstants.paddingLarge),
                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                  ),
                  child: SizedBox(
                    width: double.infinity,
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
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
          const SizedBox(height: AppConstants.paddingSmall),
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

