import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:intl/intl.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../widgets/app_scaffold.dart';
import '../components/app_app_bar.dart';
import '../widgets/empty_state_widget.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();
  final NotificationProvider _notificationProvider = NotificationProvider();
  final AuthProvider _authProvider = AuthProvider();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  // Removed local _unreadCount as it's now managed by NotificationProvider

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initPage();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreNotifications();
    }
  }

  Future<void> _initPage() async {
    await _loadNotifications();
    await _loadUnreadCount();
    if (_notificationProvider.unreadCount > 0) {
      await _markAllAsRead(silent: true);
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final response = await _notificationService.getNotifications(
        page: 1,
        pageSize: 20,
      );

      if (mounted) {
        setState(() {
          _notifications = response.results;
          _currentPage = 1;
          _hasMore = response.next != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load notifications');
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await _notificationService.getNotifications(
        page: _currentPage + 1,
        pageSize: 20,
      );

      if (mounted) {
        setState(() {
          _notifications.addAll(response.results);
          _currentPage++;
          _hasMore = response.next != null;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        _showError('Failed to load more notifications');
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      await _notificationProvider.fetchUnreadCount(_authProvider.isMerchant);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _markAllAsRead({bool silent = false}) async {
    try {
      final count = await _notificationService.markAllAsRead();

      if (mounted) {
        setState(() {
          _notifications = _notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();
        });
        _notificationProvider.resetCount();

        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count notifications marked as read'),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (!silent) {
        _showError('Failed to mark all as read');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.body),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Notifications',
        backgroundColor: Colors.transparent,
        actions: [
          ListenableBuilder(
            listenable: _notificationProvider,
            builder: (context, child) {
              if (_notificationProvider.unreadCount > 0) {
                return TextButton(
                  onPressed: () => _markAllAsRead(),
                  child: Text(
                    'Mark all read',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _initPage();
        },
        color: AppColors.accent,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_notifications.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.notifications_none,
        title: 'No notifications yet',
        message: "We'll notify you when something arrives",
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final notification = _notifications[index];
        return _NotificationTile(
          notification: notification,
          onTap: () {
            NotificationService.handleNotificationNavigation(
              context,
              notification.notificationType,
              notification.payload,
            );
          },
          formatTime: _formatTime,
          notificationService: _notificationService,
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final String Function(DateTime) formatTime;
  final NotificationService notificationService;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.formatTime,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = notificationService.getNotificationIconData(
      notification.notificationType,
    );
    final colorHex = notificationService.getNotificationColor(
      notification.notificationType,
    );
    final color = Color(
      int.parse(colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    // Clean title by removing trailing/embedded emojis if present
    final cleanTitle = notification.title
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]',
            unicode: true,
          ),
          '',
        )
        .trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : color.withValues(alpha: 0.05),
          borderRadius: AppRadius.large,
          border: Border.all(
            color: notification.isRead
                ? AppColors.cardBorder
                : color.withValues(alpha: 0.5),
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(iconData, color: color, size: 22)),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Badge
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: color.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      notification.notificationType
                          .split('_')
                          .map(
                            (w) => w.isNotEmpty
                                ? w[0] + w.substring(1).toLowerCase()
                                : '',
                          )
                          .join(' '),
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cleanTitle.isNotEmpty
                              ? cleanTitle
                              : notification.title,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatTime(notification.createdAt),
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
