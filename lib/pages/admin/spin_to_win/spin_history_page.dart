import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/admin/spin_history.dart';
import '../../../services/admin_service.dart';

class SpinHistoryPage extends StatefulWidget {
  const SpinHistoryPage({super.key});

  @override
  State<SpinHistoryPage> createState() => _SpinHistoryPageState();
}

class _SpinHistoryPageState extends State<SpinHistoryPage> {
  final AdminService _adminService = AdminService();
  final List<UserSpinResult> _history = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = false;

  final ScrollController _scrollController = ScrollController();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    _loadHistory(refresh: true);
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
        _loadHistory(refresh: false);
      }
    }
  }

  Future<void> _loadHistory({bool refresh = false}) async {
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
      final result = await _adminService.getSpinHistory(page: pageToLoad);

      setState(() {
        if (refresh) {
          _history.clear();
        }
        _history.addAll(result.results);
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
          'Spin History Log',
          style: AppTypography.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadHistory(refresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null && _history.isEmpty) {
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
              ElevatedButton(onPressed: () => _loadHistory(refresh: true), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textDisabled),
              const SizedBox(height: 16),
              Text('No Spin Logs Found', style: AppTypography.title.copyWith(fontSize: 18, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Spin history audit logs will appear here when users spin the wheel.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _history.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _history.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final item = _history[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isWin ? Colors.green.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.isWin ? Icons.emoji_events_rounded : Icons.close_rounded,
                                size: 14,
                                color: item.isWin ? Colors.green.shade900 : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.isWin ? 'WIN' : 'TRY AGAIN',
                                style: TextStyle(
                                  color: item.isWin ? Colors.green.shade900 : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'User ID: ${item.user}',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      'ID #${item.id}',
                      style: AppTypography.caption.copyWith(color: AppColors.textDisabled, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Text(
                  item.itemTitle.isNotEmpty ? item.itemTitle : 'Spin Result',
                  style: AppTypography.title.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                ),

                if (item.promoCode.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: SelectableText(
                      item.promoCode,
                      style: TextStyle(color: Colors.purple.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spun: ${_dateFormat.format(item.spunAt)}',
                      style: AppTypography.caption.copyWith(color: AppColors.textDisabled, fontSize: 11),
                    ),
                    if (item.claimedAt != null)
                      Text(
                        'Claimed: ${_dateFormat.format(item.claimedAt!)}',
                        style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
