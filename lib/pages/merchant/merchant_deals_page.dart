import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import '../../services/merchant_service.dart';
import '../../widgets/skeleton_loader.dart';
import 'add_deal_page.dart';

/// Merchant Deals Management Page
class MerchantDealsPage extends StatefulWidget {
  const MerchantDealsPage({super.key});

  @override
  State<MerchantDealsPage> createState() => _MerchantDealsPageState();
}

class _MerchantDealsPageState extends State<MerchantDealsPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _deals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Defer data loading to avoid blocking main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeals();
    });
  }

  Future<void> _loadDeals() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final deals = await _merchantService.getMerchantDeals();
      if (mounted) {
        setState(() {
          _deals = deals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load deals: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDealTypeText(String? dealType) {
    switch (dealType) {
      case 'two_for_one':
        return '2 FOR 1';
      case 'percentage':
        return 'PERCENTAGE OFF';
      case 'fixed':
        return 'FIXED AMOUNT';
      default:
        return 'DEAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.background,
      appBar: AppBar(
        title: Text(
          'My Deals',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: NeoTasteColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddDealPage(),
                ),
              ).then((_) => _loadDeals());
            },
          ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SkeletonLoader(
                  height: 140,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : _deals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_offer,
                        size: 64,
                        color: NeoTasteColors.textDisabled,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No deals yet',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first deal to attract customers',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: NeoTasteColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddDealPage(),
                            ),
                          ).then((_) => _loadDeals());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NeoTasteColors.accent,
                          foregroundColor: NeoTasteColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        child: Text(
                          'Create Deal',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDeals,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _deals.length,
                    itemBuilder: (context, index) {
                      final deal = _deals[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _DealCard(deal: deal),
                      );
                    },
                  ),
                ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Map<String, dynamic> deal;

  const _DealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    final restaurant = deal['restaurant'] as Map<String, dynamic>?;
    final restaurantName = restaurant?['name'] ?? 'Unknown';
    final title = deal['title'] ?? 'Deal';
    final dealType = deal['deal_type'] as String?;
    final isActive = deal['is_active'] as bool? ?? false;
    final usedCount = deal['used_count'] as int? ?? 0;
    final maxUses = deal['max_uses'] as int?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? NeoTasteColors.accent : NeoTasteColors.textDisabled,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: NeoTasteColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurantName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: NeoTasteColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? NeoTasteColors.accent : NeoTasteColors.textDisabled.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getDealTypeText(dealType),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? NeoTasteColors.primary : NeoTasteColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: NeoTasteColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Used: $usedCount${maxUses != null ? ' / $maxUses' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: NeoTasteColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDealTypeText(String? dealType) {
    switch (dealType) {
      case 'two_for_one':
        return '2 FOR 1';
      case 'percentage':
        return 'PERCENTAGE OFF';
      case 'fixed':
        return 'FIXED AMOUNT';
      default:
        return 'DEAL';
    }
  }
}
