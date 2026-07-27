import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discount_buddy/core/network/connectivity_provider.dart';
import 'package:discount_buddy/core/network/network_service.dart';
import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';
import 'package:discount_buddy/widgets/no_internet_view.dart';

class EnhancedPageWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool showCachedDataBanner;
  final VoidCallback? onRetry;
  final VoidCallback? onTestServer;
  final Color backgroundColor;
  final bool enableRefresh;
  final EdgeInsets? padding;

  const EnhancedPageWrapper({
    super.key,
    required this.child,
    this.onRefresh,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.showCachedDataBanner = false,
    this.onRetry,
    this.onTestServer,
    this.backgroundColor = const Color(0xFFF7F8FC),
    this.enableRefresh = true,
    this.padding,
  });

  @override
  State<EnhancedPageWrapper> createState() => _EnhancedPageWrapperState();
}

class _EnhancedPageWrapperState extends State<EnhancedPageWrapper> {
  @override
  Widget build(BuildContext context) {
    return Selector<ConnectivityProvider, bool>(
      selector: (_, p) => p.isConnected,
      builder: (context, isConnected, _) {
        final isInitializing = Provider.of<ConnectivityProvider>(context).isInitializing;

        Widget body = Column(
          children: [
            _buildConnectivityBannerFromState(isConnected, isInitializing),
            Expanded(child: _buildContent(isConnected, isInitializing)),
          ],
        );

        return Container(color: widget.backgroundColor, child: body);
      },
    );
  }

  Widget _buildConnectivityBannerFromState(bool isConnected, bool isInitializing) {
    if (!isConnected && !isInitializing) {
      return const SizedBox.shrink();
    } else if (widget.showCachedDataBanner) {
      return GestureDetector(
        onTap: _handleRefresh,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: AppColors.primary,
          child: const Row(
            children: [
              Icon(Icons.cached, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Showing cached data. Tap to refresh.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildContent(bool isConnected, bool isInitializing) {
    if (!isConnected && !isInitializing) {
      return _buildNoInternetWidget();
    }

    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.discount),
      );
    }

    if (widget.hasError) {
      return _buildErrorWidget();
    }

    if (widget.enableRefresh && widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        backgroundColor: AppColors.background,
        color: AppColors.discount,
        child: _buildScrollableContent(),
      );
    }

    return _buildScrollableContent();
  }

  Widget _buildScrollableContent() {
    // Calculate bottom padding to account for bottom navigation bar
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double bottomNavigationBarHeight = kBottomNavigationBarHeight;
    final double systemBottomPadding = mediaQuery.padding.bottom;

    // Total bottom padding includes system padding plus navigation bar height
    final double totalBottomPadding = bottomNavigationBarHeight + systemBottomPadding;

    // Use custom padding if provided, otherwise use default with proper bottom padding
    final EdgeInsets effectivePadding = widget.padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 51);

    // If custom padding is provided, ensure it has adequate bottom padding
    final EdgeInsets finalPadding = widget.padding != null
        ? EdgeInsets.fromLTRB(
            effectivePadding.left,
            effectivePadding.top,
            effectivePadding.right,
            effectivePadding.bottom < totalBottomPadding
                ? totalBottomPadding
                : effectivePadding.bottom,
          )
        : effectivePadding;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: finalPadding,
      child: widget.child,
    );
  }

  Widget _buildNoInternetWidget() {
    return NoInternetView(onRetry: widget.onRetry);
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage ?? 'An error occurred',
              style: const TextStyle(
                color: AppColors.textDarkest,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildErrorActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorActions() {
    List<Widget> actions = [];

    if (widget.onRetry != null) {
      actions.add(
        AppGradientButton(
          onPressed: widget.onRetry,
          width: 120,
          height: 40,
          child: const Text(
            'Retry',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (widget.onTestServer != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 10));
      actions.add(
        ElevatedButton(
          onPressed: widget.onTestServer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Test Server'),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: actions);
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh != null) {
      await NetworkService.handleRefresh(context, widget.onRefresh!);
    }
  }
}
