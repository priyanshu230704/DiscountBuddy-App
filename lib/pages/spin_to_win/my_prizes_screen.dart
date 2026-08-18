import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../models/spin_to_win/customer_spin_models.dart';
import '../../services/customer_spin_service.dart';

class MyPrizesScreen extends StatefulWidget {
  const MyPrizesScreen({super.key});

  @override
  State<MyPrizesScreen> createState() => _MyPrizesScreenState();
}

class _MyPrizesScreenState extends State<MyPrizesScreen> {
  final CustomerSpinService _spinService = CustomerSpinService();
  final List<CustomerSpinPrize> _prizes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPrizes(refresh: true);
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
        _loadPrizes(refresh: false);
      }
    }
  }

  Future<void> _loadPrizes({bool refresh = false}) async {
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
      final result = await _spinService.getMyPrizes(page: pageToLoad);

      setState(() {
        if (refresh) {
          _prizes.clear();
        }
        _prizes.addAll(result.results);
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

  @override
  Widget build(BuildContext context) {
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
          'My Claimed Prizes',
          style: AppTypography.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPrizes(refresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null && _prizes.isEmpty) {
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
              ElevatedButton(onPressed: () => _loadPrizes(refresh: true), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_prizes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.textDisabled),
              const SizedBox(height: 16),
              Text(
                'No Prizes Claimed Yet',
                style: AppTypography.title.copyWith(fontSize: 18, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Spin the wheel on Spin to Win to win exclusive promo codes!',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _prizes.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _prizes.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final prize = _prizes[index];
        final dateStr = prize.spunAt.toString().substring(0, 16).replaceAll('T', ' ');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1.5,
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
                        color: Colors.purple.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prize.itemTitle.isNotEmpty ? prize.itemTitle : 'Promo Prize',
                            style: AppTypography.title.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Claimed on $dateStr',
                            style: AppTypography.caption.copyWith(color: AppColors.textDisabled, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (prize.promoCode.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            prize.promoCode,
                            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: prize.promoCode));
                            Get.snackbar('Copied', 'Promo code copied to clipboard!', snackPosition: SnackPosition.BOTTOM);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text('Copy', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
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
