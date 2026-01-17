import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/deal.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/skeleton_loader.dart';
import '../discover/discover_page.dart';

/// Deals Screen - NeoTaste style
class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  List<Deal> _activeDeals = [];
  List<Deal> _usedDeals = [];
  List<Deal> _expiredDeals = [];
  bool _isLoading = true;
  String _selectedTab = 'Active';

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() {
      _isLoading = true;
    });

    // Mock data - in real app, this would come from API
    await Future.delayed(const Duration(seconds: 1));

    final mockDeals = _generateMockDeals();

    setState(() {
      _activeDeals = mockDeals.where((d) => d.status == DealStatus.active).toList();
      _usedDeals = mockDeals.where((d) => d.status == DealStatus.used).toList();
      _expiredDeals = mockDeals.where((d) => d.status == DealStatus.expired).toList();
      _isLoading = false;
    });
  }

  List<Deal> _generateMockDeals() {
    return [
      Deal(
        id: '1',
        restaurantId: '1',
        restaurantName: 'The Gourmet Kitchen',
        restaurantImageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
        title: '2-for-1 Main Course',
        description: 'Buy one main course, get one free',
        discountText: '2 FOR 1',
        validDays: ['Monday', 'Tuesday', 'Wednesday'],
        validTime: '12:00 - 15:00',
        status: DealStatus.active,
      ),
      Deal(
        id: '2',
        restaurantId: '2',
        restaurantName: 'Cafe Delight',
        restaurantImageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
        title: '50% Off Desserts',
        description: 'Half price on all desserts',
        discountText: '50% OFF',
        validDays: ['Friday', 'Saturday', 'Sunday'],
        status: DealStatus.active,
      ),
      Deal(
        id: '3',
        restaurantId: '3',
        restaurantName: 'Pizza Express',
        restaurantImageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
        title: 'Free Drink with Pizza',
        description: 'Get a free soft drink with any pizza order',
        discountText: 'FREE DRINK',
        validDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday'],
        status: DealStatus.used,
        redeemedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Deal(
        id: '4',
        restaurantId: '4',
        restaurantName: 'Sushi House',
        restaurantImageUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800',
        title: 'Lunch Special',
        description: '20% off lunch menu',
        discountText: '20% OFF',
        validDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        validTime: '11:30 - 14:30',
        status: DealStatus.expired,
        expiryDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  List<Deal> get _currentDeals {
    switch (_selectedTab) {
      case 'Active':
        return _activeDeals;
      case 'Used':
        return _usedDeals;
      case 'Expired':
        return _expiredDeals;
      default:
        return _activeDeals;
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
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: NeoTasteColors.white,
            child: Row(
              children: [
                _buildTab('Active', _activeDeals.length),
                _buildTab('Used', _usedDeals.length),
                _buildTab('Expired', _expiredDeals.length),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Deals List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDeals,
              child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SkeletonLoader(
                        height: 140,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                : _currentDeals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 64,
                              color: NeoTasteColors.textDisabled,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ${_selectedTab.toLowerCase()} deals',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: NeoTasteColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _currentDeals.length,
                        itemBuilder: (context, index) {
                          final deal = _currentDeals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _DealCard(deal: deal),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    final isSelected = _selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? NeoTasteColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? NeoTasteColors.accent
                      : NeoTasteColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? NeoTasteColors.accent
                      : NeoTasteColors.textDisabled.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? NeoTasteColors.primary
                        : NeoTasteColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deal Card
class _DealCard extends StatelessWidget {
  final Deal deal;

  const _DealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    final isUsed = deal.status == DealStatus.used;
    final isExpired = deal.status == DealStatus.expired;

    return GestureDetector(
      onTap: () {
        // Navigate to restaurant details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DiscoverPage(), // Would navigate to restaurant
          ),
        );
      },
      child: Opacity(
        opacity: isUsed || isExpired ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: NeoTasteColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpired
                  ? NeoTasteColors.textDisabled
                  : NeoTasteColors.accent,
              width: isExpired ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Restaurant Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: deal.restaurantImageUrl,
                      width: 120,
                      height: 140,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 120,
                        height: 140,
                        color: NeoTasteColors.textDisabled,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 140,
                        color: NeoTasteColors.textDisabled,
                        child: const Icon(Icons.restaurant),
                      ),
                    ),
                    if (isExpired)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant Name
                      Text(
                        deal.restaurantName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: NeoTasteColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Deal Title
                      Text(
                        deal.title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: NeoTasteColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Description
                      Text(
                        deal.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: NeoTasteColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Valid Days
                      if (deal.validDays.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: NeoTasteColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              deal.validDays.join(', '),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: NeoTasteColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      if (deal.validTime != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: NeoTasteColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              deal.validTime!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: NeoTasteColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (isUsed && deal.redeemedAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Redeemed on ${_formatDate(deal.redeemedAt!)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: NeoTasteColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Status Badge
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? NeoTasteColors.textDisabled.withOpacity(0.2)
                        : NeoTasteColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    deal.discountText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isExpired
                          ? NeoTasteColors.textSecondary
                          : NeoTasteColors.primary,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
