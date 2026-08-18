import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../design/app_typography.dart';

class SpinToWinTutorialSheet extends StatelessWidget {
  const SpinToWinTutorialSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SpinToWinTutorialSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF9333EA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Spin-to-Win Admin Guide',
                      style: AppTypography.title.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Body Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Overview Card
                _buildCard(
                  title: '1. Architecture & Concept',
                  icon: Icons.lightbulb_outline_rounded,
                  color: Colors.purple,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _GuideBullet(
                        boldText: 'Campaign (The Wheel): ',
                        normalText: 'Controls the wheel title, max daily spins per user, and ON/OFF toggle.',
                      ),
                      SizedBox(height: 6),
                      _GuideBullet(
                        boldText: 'Items (The Slices): ',
                        normalText: 'Options on the wheel (e.g., "Try Again", "50% OFF Promo Code").',
                      ),
                      SizedBox(height: 6),
                      _GuideBullet(
                        boldText: '1 Active Campaign Rule: ',
                        normalText: 'Customers always see the first active campaign. Keep only 1 campaign ACTIVE at a time.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Step-by-Step Setup
                _buildCard(
                  title: '2. Step-by-Step Setup Guide',
                  icon: Icons.checklist_rounded,
                  color: Colors.blue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _StepItem(
                        step: '1',
                        title: 'Create Campaign',
                        subtitle: 'Tap "+ New Campaign". Enter title, description, max spins/user/day (e.g. 1), and turn is_active ON.',
                      ),
                      SizedBox(height: 10),
                      _StepItem(
                        step: '2',
                        title: 'Add Slices (Min 1 Empty / Try Again)',
                        subtitle: 'Add 6 to 8 slices (indexes 0-7). ALWAYS include at least 1 "Try Again" slice (item_type: empty) as fallback.',
                      ),
                      SizedBox(height: 10),
                      _StepItem(
                        step: '3',
                        title: 'Set Probability & Restrictions',
                        subtitle: 'Higher weight = higher chance. Lock big prizes using min_spins_before_win or stock_limit.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Slices & Probabilities Deep Dive
                _buildCard(
                  title: '3. Slice Types & Rules',
                  icon: Icons.tune_rounded,
                  color: Colors.orange,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _GuideBullet(
                        boldText: 'item_type = "empty": ',
                        normalText: 'Counts as a LOSS ("Try Again"). Does not appear in customer My Prizes.',
                      ),
                      SizedBox(height: 6),
                      _GuideBullet(
                        boldText: 'item_type = "promocode": ',
                        normalText: 'Counts as a WIN. The promo_code_value text is saved to customer My Prizes.',
                      ),
                      SizedBox(height: 6),
                      _GuideBullet(
                        boldText: 'probability_weight: ',
                        normalText: 'Relative weight (e.g., 20 vs 5 makes it 4x more likely to land on).',
                      ),
                      SizedBox(height: 6),
                      _GuideBullet(
                        boldText: 'min_spins_before_win: ',
                        normalText: 'Unlocks prize after N TOTAL campaign spins across ALL users combined.',
                      ),
                      SizedBox(height: 6),
                      _GuideBullet(
                        boldText: 'stock_limit: ',
                        normalText: 'Maximum times this prize can be won overall before it is out of stock.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Day-to-Day Management
                _buildCard(
                  title: '4. Day-to-Day Management',
                  icon: Icons.settings_suggest_rounded,
                  color: Colors.green,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _GuideBullet(
                        boldText: 'Make Prize Rarer: ',
                        normalText: 'Lower probability_weight or set higher min_spins_before_win.',
                      ),
                      SizedBox(height: 6),
                      _GuideBullet(
                        boldText: 'Pause Wheel: ',
                        normalText: 'Edit campaign and set is_active = OFF. History is safely preserved.',
                      ),
                      SizedBox(height: 6),
                      _GuideBullet(
                        boldText: 'New Month / Wheel: ',
                        normalText: 'Deactivate old campaign, then create a new active campaign with fresh slices.',
                      ),
                      SizedBox(height: 6),
                      _GuideBullet(
                        boldText: 'Audit Spins: ',
                        normalText: 'Use the Audit History tab to review win/loss ratios across all users.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.title.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _GuideBullet extends StatelessWidget {
  final String boldText;
  final String normalText;

  const _GuideBullet({required this.boldText, required this.normalText});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9333EA))),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.35),
              children: [
                TextSpan(text: boldText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                TextSpan(text: normalText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;

  const _StepItem({required this.step, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF9333EA),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
