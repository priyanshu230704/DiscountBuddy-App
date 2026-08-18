import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/admin/spin_campaign.dart';
import '../../../routes/app_routes.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/admin/spin_tutorial_sheet.dart';

class SpinCampaignsListPage extends StatefulWidget {
  const SpinCampaignsListPage({super.key});

  @override
  State<SpinCampaignsListPage> createState() => _SpinCampaignsListPageState();
}

class _SpinCampaignsListPageState extends State<SpinCampaignsListPage> {
  final AdminService _adminService = AdminService();
  final List<SpinCampaign> _campaigns = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCampaigns(refresh: true);
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
        _loadCampaigns(refresh: false);
      }
    }
  }

  Future<void> _loadCampaigns({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final pageToLoad = refresh ? 1 : _currentPage + 1;
      final result = await _adminService.getCampaigns(page: pageToLoad);

      setState(() {
        if (refresh) {
          _campaigns.clear();
        }
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

  Future<void> _deleteCampaign(SpinCampaign campaign, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: Text('Are you sure you want to delete campaign "${campaign.title}"? All slice items will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteCampaign(campaign.id);
        setState(() {
          _campaigns.removeAt(index);
        });
        Get.snackbar('Deleted', 'Campaign deleted successfully.', snackPosition: SnackPosition.BOTTOM);
      } catch (e) {
        Get.snackbar('Delete Failed', 'Could not delete campaign: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _campaigns.where((c) => c.isActive).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Spin-to-Win Campaigns',
          style: AppTypography.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            tooltip: 'Spin-to-Win Guide',
            onPressed: () => SpinToWinTutorialSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.toNamed(AppRoutes.adminSpinCampaignForm);
          if (result == true) {
            _loadCampaigns(refresh: true);
          }
        },
        backgroundColor: const Color(0xFFEC4899),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Campaign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadCampaigns(refresh: true),
        child: Column(
          children: [
            // Warning Banner if multiple active campaigns
            if (activeCount > 1)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.amber.shade100,
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Warning: $activeCount campaigns are active. Backend only uses the first active campaign.',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null && _campaigns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => _loadCampaigns(refresh: true), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_campaigns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.casino_rounded, size: 64, color: AppColors.textDisabled),
              const SizedBox(height: 16),
              Text('No Campaigns Found', style: AppTypography.title.copyWith(fontSize: 18, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Tap "New Campaign" to set up your spin wheel.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _campaigns.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _campaigns.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final campaign = _campaigns[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: InkWell(
            onTap: () async {
              final result = await Get.toNamed(AppRoutes.adminSpinCampaignDetail, arguments: campaign);
              if (result == true) {
                _loadCampaigns(refresh: true);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: campaign.isActive ? const Color(0xFFEC4899).withValues(alpha: 0.15) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.casino_rounded,
                          color: campaign.isActive ? const Color(0xFFEC4899) : Colors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              campaign.title,
                              style: AppTypography.title.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            if (campaign.description.isNotEmpty)
                              Text(
                                campaign.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: campaign.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          campaign.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            color: campaign.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatBadge(label: 'Max Spins / Day', value: '${campaign.maxSpinsPerUserPerDay}'),
                      _StatBadge(label: 'Total Spins', value: '${campaign.totalSpinsCount}'),
                      _StatBadge(label: 'Wheel Slices', value: '${campaign.items.length}'),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: () => _deleteCampaign(campaign, index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;

  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textDisabled, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
