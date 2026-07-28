import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:discount_buddy/core/theme/app_design.dart';
import 'package:discount_buddy/features/merchant/data/merchant_provider.dart';
import 'package:discount_buddy/widgets/loading_widget.dart';
import 'package:discount_buddy/widgets/empty_state_widget.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'package:discount_buddy/core/utils/date_time_utils.dart';
import 'package:discount_buddy/components/inputs.dart';

class MerchantLoyaltyPage extends StatefulWidget {
  const MerchantLoyaltyPage({super.key});

  @override
  State<MerchantLoyaltyPage> createState() => _MerchantLoyaltyPageState();
}

class _MerchantLoyaltyPageState extends State<MerchantLoyaltyPage> {
  final MerchantProvider _merchantProvider = MerchantProvider();
  
  bool _isLoadingRestaurants = true;
  bool _isLoadingCustomers = false;
  bool _isLoadingHistory = false;
  bool _isClaiming = false;
  
  List<Map<String, dynamic>> _restaurants = [];
  int? _selectedRestaurantId;
  
  // Customers loyalty data
  Map<String, dynamic>? _loyaltyData;
  bool _eligibleOnly = false;
  
  // History data
  List<Map<String, dynamic>> _historyRecords = [];

  @override
  void initState() {
    super.initState();
    _loadRestaurantsAndInitialData();
  }

  Future<void> _loadRestaurantsAndInitialData() async {
    try {
      setState(() {
        _isLoadingRestaurants = true;
      });

      final result = await _merchantProvider.getMerchantRestaurants();
      
      if (!mounted) return;

      result.fold(
        onSuccess: (restaurantsList) {
          setState(() {
            _restaurants = restaurantsList;
            _isLoadingRestaurants = false;
          });

          if (_restaurants.isNotEmpty) {
            // Retrieve restaurantId from Get.arguments if present
            final args = Get.arguments;
            int? argId;
            if (args is Map && args.containsKey('restaurantId')) {
              final rawId = args['restaurantId'];
              if (rawId is int) {
                argId = rawId;
              } else if (rawId != null) {
                argId = int.tryParse(rawId.toString());
              }
            }

            // Verify if argument restaurantId actually exists in our list
            final match = _restaurants.firstWhere(
              (r) => r['id'] == argId,
              orElse: () => <String, dynamic>{},
            );

            if (match.isNotEmpty) {
              _selectedRestaurantId = argId;
            } else {
              _selectedRestaurantId = _restaurants[0]['id'] as int?;
            }

            _fetchDataForSelectedRestaurant();
          }
        },
        onError: (failure) {
          setState(() {
            _isLoadingRestaurants = false;
          });
          _showErrorSnackBar('Failed to load restaurants: ${failure.message}');
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRestaurants = false;
        });
        _showErrorSnackBar('Failed to load restaurants: ${e.toString()}');
      }
    }
  }

  Future<void> _fetchDataForSelectedRestaurant() async {
    if (_selectedRestaurantId == null) return;
    _fetchLoyaltyCustomers();
    _fetchLoyaltyHistory();
  }

  Future<void> _fetchLoyaltyCustomers() async {
    if (_selectedRestaurantId == null) return;
    
    try {
      setState(() {
        _isLoadingCustomers = true;
      });

      final result = await _merchantProvider.getLoyaltyCustomers(
        restaurantId: _selectedRestaurantId!,
        eligibleOnly: _eligibleOnly,
      );

      if (mounted) {
        result.fold(
          onSuccess: (data) {
            setState(() {
              _loyaltyData = data;
              _isLoadingCustomers = false;
            });
          },
          onError: (failure) {
            setState(() {
              _isLoadingCustomers = false;
            });
            _showErrorSnackBar('Failed to load customer list: ${failure.message}');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCustomers = false;
        });
        _showErrorSnackBar('Failed to load customer list: ${e.toString()}');
      }
    }
  }

  Future<void> _fetchLoyaltyHistory() async {
    if (_selectedRestaurantId == null) return;

    try {
      setState(() {
        _isLoadingHistory = true;
      });

      final result = await _merchantProvider.getLoyaltyHistory(
        restaurantId: _selectedRestaurantId!,
      );

      if (mounted) {
        result.fold(
          onSuccess: (history) {
            setState(() {
              _historyRecords = history;
              _isLoadingHistory = false;
            });
          },
          onError: (failure) {
            setState(() {
              _isLoadingHistory = false;
            });
            _showErrorSnackBar('Failed to load loyalty history: ${failure.message}');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
        _showErrorSnackBar('Failed to load loyalty history: ${e.toString()}');
      }
    }
  }

  Future<void> _claimReward(int userId, String customerName) async {
    if (_selectedRestaurantId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Claim',
          style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to mark the loyalty reward as claimed for $customerName? This will reset their current cycle progress.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merchantIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Claim Reward', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        _isClaiming = true;
      });

      final result = await _merchantProvider.claimLoyaltyReward(
        restaurantId: _selectedRestaurantId!,
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        _isClaiming = false;
      });

      result.fold(
        onSuccess: (data) {
          _showSuccessBottomSheet(customerName);
          _fetchDataForSelectedRestaurant();
        },
        onError: (failure) {
          _showErrorSnackBar(failure.message);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
        _showErrorSnackBar('Error claiming reward: ${e.toString()}');
      }
    }
  }

  void _showSuccessBottomSheet(String customerName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.stars_rounded,
              color: AppColors.success,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              'Reward Claimed!',
              style: AppTypography.title.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              "Successfully recorded reward redemption for $customerName. The customer's loyalty cycle has been reset.",
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            AppGradientButton(
              onPressed: () => Navigator.of(context).pop(),
              width: double.infinity,
              height: 50,
              child: Text(
                'Close',
                style: AppTypography.button.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        appBar: AppAppBar(
          titleText: 'Loyalty Program',
          bottom: const TabBar(
            labelColor: AppColors.merchantIndigo,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.merchantIndigo,
            tabs: [
              Tab(text: 'Loyalty Customers'),
              Tab(text: 'Redemption History'),
            ],
          ),
        ),
        body: _isLoadingRestaurants
            ? const LoadingWidget(message: 'Loading restaurants...')
            : _restaurants.isEmpty
                ? _buildNoRestaurantsState()
                : Column(
                    children: [
                      _buildRestaurantSelectorCard(),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildCustomersTab(),
                            _buildHistoryTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildNoRestaurantsState() {
    return EmptyStateWidget(
      icon: Icons.store_mall_directory_rounded,
      title: 'No Restaurants Found',
      message: 'You must have at least one restaurant to manage loyalty programs.',
      primaryActionLabel: 'Add Restaurant',
      onPrimaryAction: () => Get.toNamed(AppRoutes.addRestaurant),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _redirectToConfiguration() async {
    try {
      if (_selectedRestaurantId == null) return;
      setState(() {
        _isLoadingRestaurants = true;
      });
      final result = await _merchantProvider.getRestaurantDetail(_selectedRestaurantId!);
      
      if (mounted) {
        result.fold(
          onSuccess: (fullRestaurant) {
            // Inject the scrollToLoyalty flag
            fullRestaurant['scrollToLoyalty'] = true;

            final navigationFuture = Get.toNamed(
              AppRoutes.addRestaurant,
              arguments: fullRestaurant,
            );
            if (navigationFuture != null) {
              navigationFuture.then((refresh) {
                if (mounted) {
                  setState(() {
                    _isLoadingRestaurants = false;
                  });
                  if (refresh == true) {
                    _loadRestaurantsAndInitialData();
                  }
                }
              });
            } else {
              if (mounted) {
                setState(() {
                  _isLoadingRestaurants = false;
                });
              }
            }
          },
          onError: (failure) {
            if (mounted) {
              setState(() {
                _isLoadingRestaurants = false;
              });
            }
            _showErrorSnackBar('Failed to load restaurant details: ${failure.message}');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRestaurants = false;
        });
      }
      _showErrorSnackBar('Failed to load restaurant details: ${e.toString()}');
    }
  }

  Future<void> _toggleLoyaltyStatus(bool value) async {
    if (_selectedRestaurantId == null) return;

    if (value) {
      final TextEditingController redemptionsController = TextEditingController(text: '10');
      final TextEditingController rewardController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Enable Loyalty Program',
            style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set the rules for this restaurant\'s loyalty card program.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: redemptionsController,
                  label: 'Required Redemptions *',
                  hintText: 'e.g. 10',
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Required redemptions is required';
                    }
                    final num = int.tryParse(val.trim());
                    if (num == null || num < 1) {
                      return 'Must be a number greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: rewardController,
                  label: 'Reward Description *',
                  hintText: 'e.g. Free dessert on your next visit',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Reward description is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.merchantIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        setState(() {
          _isLoadingRestaurants = true;
        });

        final result = await _merchantProvider.updateRestaurant(_selectedRestaurantId!, {
          'loyalty_card_enabled': true,
          'loyalty_required_redemptions': int.parse(redemptionsController.text.trim()),
          'loyalty_reward_description': rewardController.text.trim(),
        });

        result.fold(
          onSuccess: (data) {
            _showSuccessSnackBar('Loyalty program enabled successfully');
            _loadRestaurantsAndInitialData();
          },
          onError: (failure) {
            setState(() {
              _isLoadingRestaurants = false;
            });
            _showErrorSnackBar('Failed to enable loyalty program: ${failure.message}');
          },
        );
      } catch (e) {
        setState(() {
          _isLoadingRestaurants = false;
        });
        _showErrorSnackBar('Failed to enable loyalty program: ${e.toString()}');
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Disable Loyalty Program',
            style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to disable the loyalty program? This will clear the configuration and customer progress.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Disable', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        setState(() {
          _isLoadingRestaurants = true;
        });

        final result = await _merchantProvider.updateRestaurant(_selectedRestaurantId!, {
          'loyalty_card_enabled': false,
        });

        result.fold(
          onSuccess: (data) {
            _showSuccessSnackBar('Loyalty program disabled successfully');
            _loadRestaurantsAndInitialData();
          },
          onError: (failure) {
            setState(() {
              _isLoadingRestaurants = false;
            });
            _showErrorSnackBar('Failed to disable loyalty program: ${failure.message}');
          },
        );
      } catch (e) {
        setState(() {
          _isLoadingRestaurants = false;
        });
        _showErrorSnackBar('Failed to disable loyalty program: ${e.toString()}');
      }
    }
  }

  Widget _buildRestaurantSelectorCard() {
    final bool isLoyaltyEnabled = _loyaltyData?['loyalty_card_enabled'] as bool? ?? false;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.low,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: AppColors.merchantIndigo,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedRestaurantId,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary, size: 28),
                    isExpanded: true,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    onChanged: (int? newValue) {
                      if (newValue != null && newValue != _selectedRestaurantId) {
                        setState(() {
                          _selectedRestaurantId = newValue;
                          _loyaltyData = null;
                        });
                        _fetchDataForSelectedRestaurant();
                      }
                    },
                    items: _restaurants.map<DropdownMenuItem<int>>((restaurant) {
                      return DropdownMenuItem<int>(
                        value: restaurant['id'] as int?,
                        child: Text(
                          restaurant['name'] as String? ?? 'Unnamed Restaurant',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          if (_loyaltyData != null) ...[
            const Divider(height: 24, color: AppColors.cardBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isLoyaltyEnabled ? Icons.card_membership_rounded : Icons.credit_card_off_rounded,
                        color: isLoyaltyEnabled ? AppColors.merchantIndigo : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Loyalty Card Program',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLoyaltyEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: isLoyaltyEnabled,
                  activeTrackColor: AppColors.merchantIndigo,
                  onChanged: _toggleLoyaltyStatus,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildCustomersTab() {
    if (_isLoadingCustomers && _loyaltyData == null) {
      return const LoadingWidget(message: 'Loading customers...');
    }

    if (_loyaltyData == null) {
      return const Center(child: Text('No data loaded'));
    }

    final isEnabled = _loyaltyData!['loyalty_card_enabled'] as bool? ?? false;
    
    if (!isEnabled) {
      return _buildDisabledProgramState();
    }

    final requiredRedemptions = _loyaltyData!['required_redemptions'] as int? ?? 10;
    final rewardDescription = _loyaltyData!['reward_description'] as String? ?? '';
    final customersList = List<Map<String, dynamic>>.from(_loyaltyData!['customers'] ?? []);

    return RefreshIndicator(
      onRefresh: _fetchLoyaltyCustomers,
      color: AppColors.merchantIndigo,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Program Info Card
          SliverToBoxAdapter(
            child: _buildProgramSummaryCard(requiredRedemptions, rewardDescription),
          ),

          // Filter Switch
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter: Eligible for Reward Only',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch.adaptive(
                    value: _eligibleOnly,
                    activeTrackColor: AppColors.merchantIndigo,
                    onChanged: (value) {
                      setState(() {
                        _eligibleOnly = value;
                      });
                      _fetchLoyaltyCustomers();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Customers List
          if (customersList.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: EmptyStateWidget(
                  icon: Icons.people_outline_rounded,
                  title: 'No Customers Found',
                  message: _eligibleOnly
                      ? 'No customers are currently eligible for a reward.'
                      : 'Customers will appear here once they start redeeming deals.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xxl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final customer = customersList[index];
                    return _buildCustomerCard(customer, requiredRedemptions);
                  },
                  childCount: customersList.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisabledProgramState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_membership_rounded,
                color: AppColors.error,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loyalty Card Disabled',
              style: AppTypography.title.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'The loyalty program is currently disabled for this restaurant. Enable it in the restaurant settings to start offering rewards to your customers.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            AppGradientButton(
              onPressed: _redirectToConfiguration,
              width: double.infinity,
              height: 52,
              child: Text(
                'Configure Loyalty Program',
                style: AppTypography.button.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramSummaryCard(int required, String reward) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.merchantGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Active Loyalty Card Rules',
                    style: AppTypography.title.copyWith(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                onPressed: _redirectToConfiguration,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Redemptions Required: $required',
            style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Reward: $reward',
            style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer, int requiredRedemptions) {
    final customerName = customer['user_name'] as String? ?? 'Guest';
    final customerEmail = customer['user_email'] as String? ?? 'No email';
    final currentCycleRedemptions = customer['current_cycle_redemptions'] as int? ?? 0;
    final totalLifetime = customer['total_lifetime_redemptions'] as int? ?? 0;
    final rewardsEarned = customer['rewards_earned'] as int? ?? 0;
    final lastClaimedStr = customer['last_reward_claimed_at'] as String?;
    DateTime? lastClaimedAt;
    if (lastClaimedStr != null && lastClaimedStr.isNotEmpty) {
      lastClaimedAt = DateTime.tryParse(lastClaimedStr);
    }
    final isEligible = customer['is_reward_eligible'] as bool? ?? false;
    final userId = customer['user_id'] as int? ?? 0;

    final progressPercent = requiredRedemptions > 0 
        ? (currentCycleRedemptions / requiredRedemptions).clamp(0.0, 1.0) 
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isEligible ? AppColors.merchantAmber.withValues(alpha: 0.5) : AppColors.cardBorder, width: isEligible ? 2 : 1),
        boxShadow: AppShadows.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isEligible 
                    ? AppColors.merchantAmber.withValues(alpha: 0.1) 
                    : AppColors.merchantIndigo.withValues(alpha: 0.1),
                radius: 20,
                child: Icon(
                  Icons.person_rounded,
                  color: isEligible ? AppColors.merchantAmber : AppColors.merchantIndigo,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: AppTypography.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerEmail,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isEligible)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.merchantAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.merchantAmber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'REWARD READY',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.merchantAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: $currentCycleRedemptions of $requiredRedemptions redemptions',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progressPercent * 100).toInt()}%',
                style: AppTypography.bodySmall.copyWith(
                  color: isEligible ? AppColors.merchantAmber : AppColors.merchantIndigo,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 8,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                isEligible ? AppColors.merchantAmber : AppColors.merchantIndigo,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Cycle: $currentCycleRedemptions | Lifetime: $totalLifetime | Reward Earned: $rewardsEarned',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (lastClaimedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Last Claimed: ${DateTimeUtils.formatDateTime24h(lastClaimedAt)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
              if (isEligible)
                ElevatedButton(
                  onPressed: _isClaiming ? null : () => _claimReward(userId, customerName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.merchantAmber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Claim Reward',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory && _historyRecords.isEmpty) {
      return const LoadingWidget(message: 'Loading redemption history...');
    }

    if (_historyRecords.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchLoyaltyHistory,
        color: AppColors.merchantIndigo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: EmptyStateWidget(
              icon: Icons.history_rounded,
              title: 'No History Found',
              message: 'Loyalty event logs (redemptions, claims) will appear here.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLoyaltyHistory,
      color: AppColors.merchantIndigo,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: _historyRecords.length,
        itemBuilder: (context, index) {
          final record = _historyRecords[index];
          return _buildHistoryCard(record);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final status = record['status'] as String? ?? 'counted';
    final userEmail = record['user_email'] as String? ?? 'Customer';
    final dealTitle = record['deal_title'] as String? ?? 'Deal Redeemed';
    final timestampStr = record['created_at'] as String? ?? '';
    final cycleNum = record['cycle_redemption_number'] as int? ?? 0;
    
    DateTime? timestamp;
    if (timestampStr.isNotEmpty) {
      timestamp = DateTime.tryParse(timestampStr);
    }
    
    final formattedTime = timestamp != null 
        ? DateTimeUtils.formatDateTime24h(timestamp) 
        : 'N/A';

    Color badgeColor;
    String statusLabel;
    IconData icon;

    switch (status) {
      case 'reward_claimed':
        badgeColor = AppColors.success;
        statusLabel = 'REWARD CLAIMED';
        icon = Icons.check_circle_rounded;
        break;
      case 'reward_earned':
        badgeColor = AppColors.merchantAmber;
        statusLabel = 'REWARD UNLOCKED';
        icon = Icons.emoji_events_rounded;
        break;
      case 'counted':
      default:
        badgeColor = AppColors.merchantIndigo;
        statusLabel = 'REDEMPTION COUNTED';
        icon = Icons.add_circle_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.low,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTypography.caption.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  userEmail,
                  style: AppTypography.title.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  status == 'reward_claimed' 
                      ? 'Claimed a loyalty program reward.' 
                      : '$dealTitle (Redemption #$cycleNum)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
