import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../../services/merchant_service.dart';
import '../../services/api_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/app_scaffold.dart';
import '../../components/layout.dart';
import '../../components/app_app_bar.dart';
import '../../widgets/skeleton_loader.dart';
import 'add_deal_page.dart';

/// Merchant Deals Management Page
class MerchantDealsPage extends StatefulWidget {
  final int? restaurantId;
  const MerchantDealsPage({super.key, this.restaurantId});

  @override
  State<MerchantDealsPage> createState() => _MerchantDealsPageState();
}

class _MerchantDealsPageState extends State<MerchantDealsPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _deals = [];
  List<Map<String, dynamic>> _restaurants = [];
  int? _selectedRestaurantId;
  bool _isLoading = true;
  bool _isFetching = false;
  bool _isLoadingRestaurants = true;

  @override
  void initState() {
    super.initState();
    _selectedRestaurantId = widget.restaurantId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRestaurants();
      _loadDeals();
    });
  }

  Future<void> _loadRestaurants() async {
    try {
      setState(() => _isLoadingRestaurants = true);
      final restaurants = await _merchantService.getMerchantRestaurants();
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          _isLoadingRestaurants = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRestaurants = false);
      }
    }
  }

  Future<void> _loadDeals() async {
    if (!mounted || _isFetching) return;

    try {
      setState(() {
        _isLoading = true;
        _isFetching = true;
      });

      final deals = await _merchantService.getMerchantDeals(
        restaurantId: _selectedRestaurantId,
      );
      if (mounted) {
        setState(() {
          _deals = deals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load deals: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        _isFetching = false;
      }
    }
  }

  Future<void> _toggleDealStatus(int dealId, {String? startDate, String? endDate}) async {
    // Find the deal to update locally (Optimistic Update if no dates provided)
    final dealIndex = _deals.indexWhere((d) => d['id'] == dealId);
    if (dealIndex == -1) return;

    final deal = _deals[dealIndex];
    final originalStatus = deal['is_active'] ?? false;
    
    // Only do optimistic update if we are doing a simple toggle without dates
    if (startDate == null && endDate == null) {
      setState(() {
        _deals[dealIndex]['is_active'] = !originalStatus;
      });
    }

    try {
      final response = await _merchantService.toggleDealStatus(
        dealId, 
        startDate: startDate, 
        endDate: endDate
      );
      
      if (mounted) {
        if (response['success'] == true) {
          // Update local deal with returned deal object
          if (response['deal'] != null) {
            setState(() {
              _deals[dealIndex] = response['deal'];
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['detail'] ?? 'Status updated'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );

          // Show warnings if any
          if (response['warnings'] != null && (response['warnings'] as List).isNotEmpty) {
            _showWarningsDialog(response['warnings'].cast<String>());
          }
        } else {
          // Handle explicit failure if success is false but no exception thrown
          if (startDate == null && endDate == null) {
            setState(() {
              _deals[dealIndex]['is_active'] = originalStatus;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['detail'] ?? 'Failed to update status'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Revert on error if we did optimistic update
        if (startDate == null && endDate == null) {
          setState(() {
            _deals[dealIndex]['is_active'] = originalStatus;
          });
        }

        if (e is ApiException && e.data != null && e.data['error_code'] == 'EXPIRED_DEAL') {
          _showRenewDealDialog(dealId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showWarningsDialog(List<String> warnings) {
    // Filter out confusing/incorrect warnings from backend if they contradict the successful toggle
    final filteredWarnings = warnings.where((w) {
      final lowercaseW = w.toLowerCase();
      // Remove warnings that say it's still inactive when we just toggled it on
      if (lowercaseW.contains('inactive') && (lowercaseW.contains('toggled on') || lowercaseW.contains('toggle on'))) {
        return false;
      }
      return true;
    }).toList();

    if (filteredWarnings.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.merchantAmber),
            SizedBox(width: 8),
            Text('Important Note'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filteredWarnings.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text('• $w', style: AppTypography.bodySmall),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenewDealDialog(int dealId) async {
    final dealIndex = _deals.indexWhere((d) => d['id'] == dealId);
    if (dealIndex == -1) return;
    
    DateTime now = DateTime.now();
    // Default to starting now and ending in 30 days
    DateTime initialStart = now;
    DateTime initialEnd = now.add(const Duration(days: 30));

    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) => _RenewDealDialog(
        initialStartDate: initialStart,
        initialEndDate: initialEnd,
      ),
    );

    if (result != null) {
      final startDateStr = result['startDate']!.toUtc().toIso8601String();
      final endDateStr = result['endDate']!.toUtc().toIso8601String();
      _toggleDealStatus(dealId, startDate: startDateStr, endDate: endDateStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Active Deals',
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryOrange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddDealPage()),
              ).then((_) => _loadDeals());
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRestaurantFilter(),
          if (!_isLoading && _deals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
              child: Text(
                '${_deals.where((d) => d['is_active'] == true).length} Active Deal${_deals.where((d) => d['is_active'] == true).length == 1 ? '' : 's'}',
                style: AppTypography.title.copyWith(fontSize: 18),
              ),
            ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _deals.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadDeals,
                    color: AppColors.primaryOrange,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.sm,
                        AppSpacing.xl,
                        AppSpacing.xxxl,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _deals.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, index) {
                        return _DealCard(
                          deal: _deals[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddDealPage(deal: _deals[index]),
                              ),
                            ).then((_) => _loadDeals());
                          },
                          onToggle: (isActive) {
                            _toggleDealStatus(_deals[index]['id']);
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: SkeletonLoader(
          height: 140,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.local_offer_rounded,
      title: 'No active deals',
      message: 'Create a deal to attract more customers.',
      primaryActionLabel: 'Create deal',
      onPrimaryAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddDealPage()),
        ).then((_) => _loadDeals());
      },
    );
  }

  Widget _buildRestaurantFilter() {
    if (_isLoadingRestaurants && _restaurants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        scrollDirection: Axis.horizontal,
        itemCount: _restaurants.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final restaurant = isAll ? null : _restaurants[index - 1];
          final id = isAll ? null : restaurant!['id'];
          final name = isAll ? 'All Restaurants' : restaurant!['name'];
          final isSelected = _selectedRestaurantId == id;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedRestaurantId = id;
              });
              _loadDeals();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.purpleGradient : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Text(
                name,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Map<String, dynamic> deal;
  final VoidCallback onTap;
  final Function(bool) onToggle;

  const _DealCard({
    required this.deal,
    required this.onTap,
    required this.onToggle,
  });

  String _getDealTypeText(String? dealType) {
    switch (dealType) {
      case 'two_for_one':
        return '2-for-1 Deal';
      case 'percentage':
        return '% Discount';
      case 'fixed':
        return 'Fixed Price';
      default:
        return 'Offer';
    }
  }

  IconData _getDealIcon(String? dealType) {
    switch (dealType) {
      case 'two_for_one':
        return Icons.people_alt_rounded;
      case 'percentage':
        return Icons.percent_rounded;
      case 'fixed':
        return Icons.attach_money_rounded;
      default:
        return Icons.local_offer_rounded;
    }
  }

  Color _getDealColor(String? dealType) {
    switch (dealType) {
      case 'two_for_one':
        return AppColors.merchantIndigo;
      case 'percentage':
        return AppColors.merchantAmber;
      case 'fixed':
        return AppColors.merchantTeal;
      default:
        return AppColors.primaryOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = deal['restaurant'] as Map<String, dynamic>?;
    final restaurantName = restaurant?['name'] ?? 'Unknown Restaurant';
    final title = deal['title'] ?? 'Untitled Deal';
    final dealType = deal['deal_type'] as String?;
    final isActive = deal['is_active'] as bool? ?? false;
    final usedCount = deal['used_count'] as int? ?? 0;
    final maxUses = deal['max_uses'] as int?;

    final endDateStr = deal['end_date'] as String?;
    final endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;
    final isExpired = endDate != null && endDate.isBefore(DateTime.now());

    final iconColor = _getDealColor(dealType);
    final iconData = _getDealIcon(dealType);

    double progress = 0;
    if (maxUses != null && maxUses > 0) {
      progress = (usedCount / maxUses).clamp(0.0, 1.0);
    }

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.title.copyWith(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurantName,
                            style: AppTypography.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'EXPIRED',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch.adaptive(
                value: isActive,
                onChanged: onToggle,
                activeThumbColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _InfoTag(
                icon: Icons.local_offer_outlined,
                label: _getDealTypeText(dealType),
              ),
              const Spacer(),
              if (maxUses != null)
                Text(
                  '$usedCount / $maxUses used',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  '$usedCount used',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (maxUses != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.shimmer,
                color: progress > 0.9 ? AppColors.error : AppColors.merchantBlue,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewDealDialog extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;

  const _RenewDealDialog({
    required this.initialStartDate,
    required this.initialEndDate,
  });

  @override
  State<_RenewDealDialog> createState() => _RenewDealDialogState();
}

class _RenewDealDialogState extends State<_RenewDealDialog> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryOrange,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Ensure end date is after start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renew Expired Deal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This deal has expired. Please set a new date range to reactivate it.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildDateTile('Start Date', _startDate, () => _selectDate(true)),
          const SizedBox(height: AppSpacing.md),
          _buildDateTile('End Date', _endDate, () => _selectDate(false)),
          if (_endDate.isBefore(_startDate))
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'End date must be after start date',
                style: AppTypography.caption.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _endDate.isAfter(_startDate)
              ? () => Navigator.pop(context, {
                    'startDate': _startDate,
                    'endDate': _endDate,
                  })
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Renew & Activate'),
        ),
      ],
    );
  }

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primaryOrange),
          ],
        ),
      ),
    );
  }
}
