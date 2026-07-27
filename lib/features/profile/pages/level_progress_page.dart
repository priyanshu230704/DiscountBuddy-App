import 'dart:async';
import 'package:flutter/material.dart';
import 'package:discount_buddy/core/theme/app_design.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/widgets/generic_bottom_sheet.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';

class LevelProgressPage extends StatefulWidget {
  final ProfileStats stats;

  const LevelProgressPage({super.key, required this.stats});

  @override
  State<LevelProgressPage> createState() => _LevelProgressPageState();
}

class _LevelProgressPageState extends State<LevelProgressPage> {
  late Timer _countdownTimer;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _remainingTime = Duration(seconds: widget.stats.weekly.resetTimerSeconds);
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (_remainingTime.inSeconds <= 0) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime -= const Duration(seconds: 1);
          } else {
            _countdownTimer.cancel();
          }
        });
      }
    });
  }

  String _formatRemainingTime() {
    int days = _remainingTime.inDays;
    int hours = _remainingTime.inHours % 24;
    int minutes = _remainingTime.inMinutes % 60;
    return "${days}d ${hours}h ${minutes}m";
  }

  IconData _getBadgeIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'shield':
        return Icons.shield;
      case 'star':
        return Icons.star;
      case 'coffee':
        return Icons.coffee;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'celebration':
        return Icons.celebration;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'savings':
        return Icons.savings;
      case 'verified':
        return Icons.verified;
      case 'favorite':
        return Icons.favorite;
      case 'history_edu':
        return Icons.history_edu;
      default:
        return Icons.emoji_events;
    }
  }

  void _showInfoBottomSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GenericBottomSheet(
        title: title,
        showCloseButton: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppGradientButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Got it!",
                    style: AppTypography.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // backgroundColor set to null to default to AppColors.backgroundGradient in AppScaffold
      appBar: AppAppBar(
        titleText: 'Level Details',
        centerTitle: true,
        backgroundColor: Colors.transparent, // Seamless transition into gradient
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentTierCard(),
            const SizedBox(height: 32),
            _buildTierProgressWidget(),
            const SizedBox(height: 32),
            _buildWeeklyResetWidget(),
            const SizedBox(height: 32),
            _buildBadgesSection(),
            const SizedBox(height: 32), // Add bottom padding for better scroll
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTierCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.xLarge,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.stats.progression.tier,
            style: AppTypography.headline.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.stats.progression.rank,
            style: AppTypography.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${widget.stats.progression.currentPoints} Points Total",
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgressWidget() {
    final prog = widget.stats.progression;
    if (prog.nextTier == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: AppRadius.large,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            "Maximum Tier Reached! 🏆",
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    final next = prog.nextTier!;
    final progress = (next['progress_percentage'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Tier Progress",
              style: AppTypography.title.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              onPressed: () => _showInfoBottomSheet(
                "Tier Progression",
                "Earn points by claiming deals and visiting restaurants. Collect enough points to reach the next tier and unlock premium rewards!",
              ),
              icon: Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "To: ${next['name']}",
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "${next['points_remaining']} pts left",
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  color: AppColors.primary,
                  minHeight: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyResetWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Weekly Activity",
              style: AppTypography.title.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              onPressed: () => _showInfoBottomSheet(
                "Weekly Reset",
                "Your bonus points and specific mini-challenges reset every week. Track the timer to ensure you've maximized your savings before the reset!",
              ),
              icon: Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _remainingTime.inSeconds > 0
                          ? "Resets In"
                          : "Resetting Soon",
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.stats.weekly.resetMessage,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatRemainingTime(),
                style: AppTypography.headline.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Your Achievements",
              style: AppTypography.title.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              onPressed: () => _showInfoBottomSheet(
                "Achievement Badges",
                "Badges are awarded for special milestones like 'First 10 Savings' or 'Weekend Warrior'. Collect them all to prove you're the ultimate Discount Buddy!",
              ),
              icon: Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 24,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: widget.stats.badges.length,
          itemBuilder: (context, index) {
            final badge = widget.stats.badges[index];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: badge.earned
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: badge.earned
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          )
                        : null,
                  ),
                  child: Opacity(
                    opacity: badge.earned ? 1.0 : 0.2,
                    child: Icon(
                      _getBadgeIcon(badge.icon),
                      size: 28,
                      color: badge.earned
                          ? AppColors.primary
                          : AppColors.textDisabled,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    badge.name,
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      fontWeight: badge.earned
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: badge.earned
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
