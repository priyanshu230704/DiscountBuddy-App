import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/admin/notification_campaign.dart';
import '../../../routes/app_routes.dart';
import '../../../services/admin_service.dart';
import '../../../utils/date_time_utils.dart';

class NotificationCampaignsListPage extends StatefulWidget {
  const NotificationCampaignsListPage({super.key});

  @override
  State<NotificationCampaignsListPage> createState() => _NotificationCampaignsListPageState();
}

class _NotificationCampaignsListPageState extends State<NotificationCampaignsListPage> {
  final AdminService _adminService = AdminService();
  final List<AdminNotificationCampaign> _campaigns = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _load(refresh: false);
      }
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final pageToLoad = refresh ? 1 : _currentPage + 1;
      final result = await _adminService.getNotificationCampaigns(page: pageToLoad);
      setState(() {
        if (refresh) _campaigns.clear();
        _campaigns.addAll(result.results);
        _currentPage = pageToLoad;
        _hasMore = result.next != null;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _openCompose() async {
    final sent = await Get.toNamed(AppRoutes.adminNotificationCompose);
    if (sent == true) {
      _load(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Notifications',
          style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCompose,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.campaign_rounded, color: Colors.white),
        label: const Text('Compose', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                  onRefresh: () => _load(refresh: true),
                  child: _campaigns.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No promo notifications sent yet.')),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _campaigns.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _campaigns.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final campaign = _campaigns[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.textDisabled.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          campaign.title,
                                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Text(
                                        campaign.status.toUpperCase(),
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: campaign.status == 'failed' ? Colors.red : AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    campaign.message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    [
                                      campaign.audienceLabel,
                                      if (campaign.restaurantName != null) campaign.restaurantName!,
                                      if (campaign.status == 'scheduled' && campaign.scheduledAt != null)
                                        'Scheduled for ${DateTimeUtils.formatBookingDateTimeFromIso(campaign.scheduledAt)}'
                                      else if (campaign.status == 'sent')
                                        '${campaign.recipientCount} recipients',
                                    ].join(' · '),
                                    style: AppTypography.caption.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
