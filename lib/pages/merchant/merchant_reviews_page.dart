import 'package:flutter/material.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/design/app_spacing.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:discount_buddy/components/layout.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import '../../services/merchant_service.dart';
import '../../widgets/skeleton_loader.dart';

class MerchantReviewsPage extends StatefulWidget {
  const MerchantReviewsPage({super.key});

  @override
  State<MerchantReviewsPage> createState() => _MerchantReviewsPageState();
}

class _MerchantReviewsPageState extends State<MerchantReviewsPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (_isFetching) return;

    try {
      setState(() {
        _isLoading = true;
        _isFetching = true;
      });

      final reviews = await _merchantService.getMerchantReviews();
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reviews: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        _isFetching = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        titleText: 'Reviews',
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _reviews.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadReviews,
              color: AppColors.accent,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.xl),
                itemCount: _reviews.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return _ReviewCard(review: review);
                },
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: SkeletonLoader(
          height: 140,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.rate_review_rounded,
      title: 'No reviews yet',
      message: 'Customer feedback will appear here once you receive reviews.',
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final user = review['user_name'] ?? 'Anonymous';
    final restaurant = review['restaurant_name'] ?? 'Restaurant';
    final rating = (review['rating'] ?? 0);
    final comment = review['comment'] ?? '';
    final date = review['created_at'] ?? '';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  user,
                  style: AppTypography.title.copyWith(fontSize: 16),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 18,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            restaurant,
            style: AppTypography.bodySmall,
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              comment,
              style: AppTypography.body,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            date,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
