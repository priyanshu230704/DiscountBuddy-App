import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:discount_buddy/core/theme/app_design.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/features/merchant/data/merchant_service.dart';
import 'dart:async';

class MerchantRemindersPage extends StatefulWidget {
  const MerchantRemindersPage({super.key});

  @override
  State<MerchantRemindersPage> createState() => _MerchantRemindersPageState();
}

class _MerchantRemindersPageState extends State<MerchantRemindersPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    // Refresh countdown every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    try {
      setState(() => _isLoading = true);
      final reminders = await _merchantService.getUpcomingReminders();
      if (mounted) {
        setState(() {
          _reminders = reminders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCountdownText(String? dateStr) {
    if (dateStr == null) return '';
    final bookingDate = DateTime.tryParse(dateStr);
    if (bookingDate == null) return '';

    final now = DateTime.now();
    final difference = bookingDate.difference(now);

    if (difference.isNegative) {
      final mins = difference.inMinutes.abs();
      if (mins < 60) {
        return '$mins min ago';
      }
      final hours = difference.inHours.abs();
      return '$hours hrs ago';
    } else {
      final totalMins = difference.inMinutes;
      if (totalMins < 60) {
        return 'In $totalMins min';
      }
      final hours = difference.inHours;
      final mins = totalMins % 60;
      if (mins == 0) {
        return 'In ${hours}h';
      }
      return 'In ${hours}h ${mins}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Manager Reminders',
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.merchantIndigo))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadReminders,
                    color: AppColors.merchantIndigo,
                    child: _reminders.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            itemCount: _reminders.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _buildReminderCard(_reminders[index]);
                            },
                          ),
                  ),
                ),
                _buildInfoBanner(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Icon(Icons.notifications_off_outlined, size: 60, color: AppColors.textDisabled),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No upcoming reminders',
            style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Reminders appear here 1 hour before user bookings.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final customer = reminder['contact_name'] ?? 'Guest';
    final guests = reminder['number_of_guests'] ?? 0;
    final dateStr = reminder['booking_date'];
    final initial = customer.toString().substring(0, 1).toUpperCase();

    DateTime? date;
    if (dateStr != null) {
      date = DateTime.tryParse(dateStr);
    }
    
    final formattedTime = date != null
        ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : 'N/A';
    final formattedDate = date != null
        ? '${date.day.toString().padLeft(2, '0')} ${_getMonthShort(date.month)} ${date.year}'
        : 'N/A';

    final countdownText = _getCountdownText(dateStr);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
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
          // Circular initials avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.merchantIndigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTypography.title.copyWith(
                color: AppColors.merchantIndigo,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$formattedTime - $customer',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    // Countdown badge
                    if (countdownText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.merchantIndigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          countdownText,
                          style: TextStyle(
                            color: AppColors.merchantIndigo,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$guests Guests • $formattedDate',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.merchantIndigo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.merchantIndigo.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.merchantIndigo, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You will get a reminder 1 hour before every confirmed booking.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.merchantIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthShort(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
