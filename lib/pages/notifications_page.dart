import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../design/app_colors.dart';
import '../../design/app_radius.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../components/layout.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    if (_unreadCount > 0) {
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
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
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
          _unreadCount = 0;
        });

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AppTypography.title),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () => _markAllAsRead(),
              child: Text(
                'Mark all read',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
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
          onTap: () {},
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
    final icon = notificationService.getNotificationIcon(
      notification.notificationType,
    );
    final colorHex = notificationService.getNotificationColor(
      notification.notificationType,
    );
    final color = Color(
      int.parse(colorHex.substring(1), radix: 16) + 0xFF000000,
    );

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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
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
                          notification.title,
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
