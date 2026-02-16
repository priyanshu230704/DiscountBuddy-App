import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../models/deal_redemption.dart';
import '../../services/restaurant_service.dart';
import '../restaurant_details_page.dart';

/// Bookings/Redemptions Screen - Integrated with deal uses API
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  final RestaurantService _restaurantService = RestaurantService();
  List<DealRedemption> _redemptions = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRedemptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRedemptions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final redemptions = await _restaurantService.getUserDealRedemptions();
      if (mounted) {
        setState(() {
          _redemptions = redemptions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load history: $e')));
      }
    }
  }

  List<DealRedemption> _getRedemptionsByTab(int index) {
    // Sort by date descending
    final sortedList = List<DealRedemption>.from(_redemptions)
      ..sort((a, b) => b.usedAt.compareTo(a.usedAt));

    switch (index) {
      case 0: // Active (Not redeemed/Complete if logical)
        // Assuming "Active" means not yet confirmed by restaurant or redeemed
        // But the user just wants to see the list.
        // Let's filter by: restaurant_confirmed == false -> Active?
        return sortedList.where((r) => !r.restaurantConfirmed).toList();
      case 1: // History (Redeemed/Confirmed)
        return sortedList.where((r) => r.restaurantConfirmed).toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.white,
      appBar: AppBar(
        title: Text(
          'My Coupons & Offers',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: NeoTasteColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: NeoTasteColors.textSecondary,
          indicatorColor: Colors.green,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : TabBarView(
              controller: _tabController,
              children: [
                _RedemptionList(
                  redemptions: _getRedemptionsByTab(0),
                  onRefresh: _loadRedemptions,
                  emptyMessage: 'No active coupons',
                ),
                _RedemptionList(
                  redemptions: _getRedemptionsByTab(1),
                  onRefresh: _loadRedemptions,
                  emptyMessage: 'No history',
                ),
              ],
            ),
    );
  }
}

class _RedemptionList extends StatelessWidget {
  final List<DealRedemption> redemptions;
  final Future<void> Function() onRefresh;
  final String emptyMessage;

  const _RedemptionList({
    required this.redemptions,
    required this.onRefresh,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (redemptions.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
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
                    emptyMessage,
                    style: GoogleFonts.inter(
                      color: NeoTasteColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: redemptions.length,
        itemBuilder: (context, index) {
          return _RedemptionCard(redemption: redemptions[index]);
        },
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  final DealRedemption redemption;

  const _RedemptionCard({required this.redemption});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoTasteColors.textDisabled.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showRedemptionDetails(context, redemption),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          redemption.deal.restaurantName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: NeoTasteColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          redemption.deal.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: NeoTasteColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(isConfirmed: redemption.restaurantConfirmed),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: NeoTasteColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Used: ${DateFormat('MMM d, yyyy HH:mm').format(redemption.usedAt)}',
                    style: GoogleFonts.inter(
                      color: NeoTasteColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (redemption.redemptionCode != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.qr_code,
                      size: 16,
                      color: NeoTasteColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Code: ${redemption.redemptionCode}',
                      style: GoogleFonts.inter(
                        color: NeoTasteColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRedemptionDetails(BuildContext context, DealRedemption redemption) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RedemptionDetailModal(redemption: redemption),
    );
  }
}

class _RedemptionDetailModal extends StatelessWidget {
  final DealRedemption redemption;
  const _RedemptionDetailModal({required this.redemption});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NeoTasteColors.textDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              redemption.deal.restaurantName,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            _StatusBadge(
                              isConfirmed: redemption.restaurantConfirmed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // QR Code Logic
                      if (redemption.qrCodeUrl != null &&
                          redemption.qrCodeUrl!.isNotEmpty) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: NeoTasteColors.textDisabled.withOpacity(
                                  0.2,
                                ),
                              ),
                            ),
                            child: Image.network(
                              // Handle localhost replacement if strictly needed,
                              // but ideally backend sends accessible URLs
                              redemption.qrCodeUrl!
                                  .replaceAll(
                                    'localhost',
                                    '10.0.2.2',
                                  ) // Android emulator fix just in case
                                  .replaceAll('127.0.0.1', '10.0.2.2'),
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (redemption.redemptionCode != null) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              redemption.redemptionCode!,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      _DetailRow(
                        icon: Icons.local_offer,
                        label: 'Offer',
                        value: redemption.deal.title, // or displayText logic
                      ),
                      const SizedBox(height: 16),
                      // Deal Details
                      if (redemption.deal.discountPercentage != null)
                        _DetailRow(
                          icon: Icons.percent,
                          label: 'Discount',
                          value:
                              '${redemption.deal.discountPercentage!.toStringAsFixed(0)}% OFF',
                        ),
                      if (redemption.deal.discountAmount != null)
                        _DetailRow(
                          icon: Icons.attach_money,
                          label: 'Fixed Discount',
                          value: '£${redemption.deal.discountAmount}',
                        ),

                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: 'Used On',
                        value: DateFormat(
                          'EEEE, MMM d, yyyy HH:mm',
                        ).format(redemption.usedAt),
                      ),

                      if (redemption.notes != null &&
                          redemption.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: Icons.note,
                          label: 'Notes',
                          value: redemption.notes!,
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailsPage(
                          slug: redemption.deal.restaurantSlug,
                        ),
                      ),
                    );
                  },
                  child: const Text('View Restaurant'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: NeoTasteColors.textSecondary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: NeoTasteColors.textDisabled,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: NeoTasteColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isConfirmed;

  const _StatusBadge({required this.isConfirmed});

  @override
  Widget build(BuildContext context) {
    // If restaurant_confirmed is true -> Confirmed (Green)
    // If false -> Pending/Active (Orange)

    final color = isConfirmed ? Colors.green : Colors.orange;
    final text = isConfirmed ? 'Confirmed' : 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
