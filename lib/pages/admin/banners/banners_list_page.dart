import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/admin/app_banner.dart';
import '../../../routes/app_routes.dart';
import '../../../services/admin_service.dart';

class BannersListPage extends StatefulWidget {
  const BannersListPage({super.key});

  @override
  State<BannersListPage> createState() => _BannersListPageState();
}

class _BannersListPageState extends State<BannersListPage> {
  final AdminService _adminService = AdminService();
  final List<AppBanner> _banners = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBanners(refresh: true);
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
        _loadBanners(refresh: false);
      }
    }
  }

  Future<void> _loadBanners({bool refresh = false}) async {
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
      final result = await _adminService.getBanners(page: pageToLoad);

      setState(() {
        if (refresh) {
          _banners.clear();
        }
        _banners.addAll(result.results);
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

  Future<void> _toggleBannerActive(AppBanner banner, int index) async {
    final previousState = banner.isVisible;
    // Optimistic UI update
    setState(() {
      _banners[index] = AppBanner(
        id: banner.id,
        title: banner.title,
        body: banner.body,
        ctaUrl: banner.ctaUrl,
        priority: banner.priority,
        isVisible: !previousState,
        imageMedium: banner.imageMedium,
        imageLarge: banner.imageLarge,
        createdAt: banner.createdAt,
        updatedAt: banner.updatedAt,
      );
    });

    try {
      final newStatus = await _adminService.toggleBannerVisible(banner.id);
      Get.snackbar(
        'Status Updated',
        'Banner is now ${newStatus ? "Visible" : "Hidden"}.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // Rollback on error
      setState(() {
        _banners[index] = banner;
      });
      Get.snackbar(
        'Toggle Failed',
        'Could not toggle visibility: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteBanner(AppBanner banner, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: Text('Are you sure you want to delete banner "${banner.title}"?'),
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
        await _adminService.deleteBanner(banner.id);
        setState(() {
          _banners.removeAt(index);
        });
        Get.snackbar(
          'Deleted',
          'Banner deleted successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Delete Failed',
          'Could not delete banner: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
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
          'Banner Management',
          style: AppTypography.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.toNamed(AppRoutes.adminBannerForm);
          if (result == true) {
            _loadBanners(refresh: true);
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Banner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadBanners(refresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null && _banners.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadBanners(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_banners.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.view_carousel_rounded, size: 64, color: AppColors.textDisabled),
              const SizedBox(height: 16),
              Text(
                'No Banners Found',
                style: AppTypography.title.copyWith(fontSize: 18, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Add Banner" below to create your first promotional banner.',
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
      itemCount: _banners.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _banners.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final banner = _banners[index];
        final imageUrl = banner.displayImage;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Thumbnail Image Header
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 140,
                      color: AppColors.background,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 140,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 90,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_outlined, color: AppColors.primary, size: 36),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            banner.title ?? 'Untitled Banner',
                            style: AppTypography.title.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: banner.isVisible,
                          activeTrackColor: AppColors.primary,
                          onChanged: (_) => _toggleBannerActive(banner, index),
                        ),
                      ],
                    ),

                    if (banner.body != null && banner.body!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        banner.body!,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Priority: ${banner.priority}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Visibility Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: banner.isVisible ? Colors.green.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            banner.isVisible ? 'Visible' : 'Hidden',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: banner.isVisible ? Colors.green.shade800 : Colors.grey.shade700,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Edit Button
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                          onPressed: () async {
                            final result = await Get.toNamed(
                              AppRoutes.adminBannerForm,
                              arguments: banner,
                            );
                            if (result == true) {
                              _loadBanners(refresh: true);
                            }
                          },
                        ),

                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          onPressed: () => _deleteBanner(banner, index),
                        ),
                      ],
                    ),

                    if (banner.ctaUrl.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'CTA Link: ${banner.ctaUrl}',
                        style: AppTypography.caption.copyWith(color: AppColors.textDisabled, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
