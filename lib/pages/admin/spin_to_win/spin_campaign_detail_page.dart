import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/admin/spin_campaign.dart';
import '../../../models/admin/spin_item.dart';
import '../../../routes/app_routes.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/admin/spin_tutorial_sheet.dart';

class SpinCampaignDetailPage extends StatefulWidget {
  const SpinCampaignDetailPage({super.key});

  @override
  State<SpinCampaignDetailPage> createState() => _SpinCampaignDetailPageState();
}

class _SpinCampaignDetailPageState extends State<SpinCampaignDetailPage> {
  final AdminService _adminService = AdminService();
  late SpinCampaign _campaign;

  List<SpinItem> _items = [];
  bool _isLoadingItems = true;
  String? _itemErrorMessage;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is SpinCampaign) {
      _campaign = args;
      _items = List.from(args.items);
      _loadItems();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
      });
    }
  }

  Future<void> _loadCampaignDetail() async {
    try {
      final updated = await _adminService.getCampaign(_campaign.id);
      setState(() {
        _campaign = updated;
      });
    } catch (e) {
      debugPrint('Error fetching campaign detail: $e');
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoadingItems = true;
      _itemErrorMessage = null;
    });

    try {
      final result = await _adminService.getItems(campaignId: _campaign.id);
      setState(() {
        _items = result.results;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _itemErrorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingItems = false;
      });
    }
  }

  Future<void> _deleteItem(SpinItem item, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slice Item'),
        content: Text('Are you sure you want to delete wheel slice "${item.title}"?'),
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
        await _adminService.deleteItem(item.id);
        setState(() {
          _items.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wheel slice deleted.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete slice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEmptySlice = _items.any((i) => i.itemType == SpinItemType.empty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Get.back(result: true),
        ),
        title: Text(
          _campaign.title,
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
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit Settings',
            onPressed: () async {
              final result = await Get.toNamed(AppRoutes.adminSpinCampaignForm, arguments: _campaign);
              if (result == true) {
                await _loadCampaignDetail();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.toNamed(
            AppRoutes.adminSpinItemForm,
            arguments: {'campaignId': _campaign.id},
          );
          if (result == true) {
            _loadItems();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Slice Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadCampaignDetail();
          await _loadItems();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign Overview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Campaign Settings', style: AppTypography.title.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _campaign.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _campaign.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              color: _campaign.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_campaign.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_campaign.description, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _InfoTile(label: 'Max Spins/Day', value: '${_campaign.maxSpinsPerUserPerDay}')),
                        Expanded(child: _InfoTile(label: 'Total Spins', value: '${_campaign.totalSpinsCount}')),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Empty slice warning tip if missing
              if (!hasEmptySlice && !_isLoadingItems) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.orange.shade900),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tip: Add at least one "Try Again" (Empty) slice so the wheel can fail closed when prizes are locked.',
                          style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Slices / Items Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Wheel Slices (${_items.length})',
                    style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildItemsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isLoadingItems) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_itemErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_itemErrorMessage', style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.pie_chart_outline_rounded, size: 48, color: AppColors.textDisabled),
              const SizedBox(height: 12),
              Text('No Wheel Slices Configured', style: AppTypography.title.copyWith(fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Tap "Add Slice Item" to add wheel rewards.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final displayImg = item.displayImage;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: displayImg != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(imageUrl: displayImg, fit: BoxFit.cover),
                            )
                          : Center(
                              child: Text(item.icon.isNotEmpty ? item.icon : '🎁', style: const TextStyle(fontSize: 22)),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Slice ${item.sliceIndex}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: AppTypography.title.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          _ItemTypeBadge(type: item.itemType),
                        ],
                      ),
                    ),

                    // Actions
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                      onPressed: () async {
                        final result = await Get.toNamed(
                          AppRoutes.adminSpinItemForm,
                          arguments: item,
                        );
                        if (result == true) {
                          _loadItems();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: () => _deleteItem(item, index),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Stats Grid for min spins, stock, weight, won
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MiniStat(label: 'Min Spins', value: '${item.minSpinsBeforeWin}'),
                    _MiniStat(label: 'Stock Limit', value: item.stockLimit != null ? '${item.stockLimit}' : '∞'),
                    _MiniStat(label: 'Weight', value: '${item.probabilityWeight}'),
                    _MiniStat(label: 'Times Won', value: '${item.timesWon}'),
                  ],
                ),

                if (item.promoCodeValue.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Promo: ${item.promoCodeValue}',
                      style: AppTypography.caption.copyWith(color: Colors.black87, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textDisabled, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ItemTypeBadge extends StatelessWidget {
  final SpinItemType type;

  const _ItemTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (type) {
      case SpinItemType.promocode:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        label = 'Promo Code';
        break;
      case SpinItemType.discount:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        label = 'Discount';
        break;
      case SpinItemType.points:
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade900;
        label = 'Points';
        break;
      case SpinItemType.empty:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        label = 'Try Again (Empty)';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
