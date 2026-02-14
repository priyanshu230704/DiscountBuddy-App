# Notification System Architecture

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐         ┌──────────────────┐                 │
│  │  HomePage    │────────▶│ NotificationsPage│                 │
│  │              │         │                  │                 │
│  │  [🔔 Badge]  │         │  • List view     │                 │
│  │  Count: 5    │         │  • Pagination    │                 │
│  └──────┬───────┘         │  • Mark as read  │                 │
│         │                 │  • Pull refresh  │                 │
│         │                 └────────┬─────────┘                 │
│         │                          │                            │
│         │                          │                            │
│         └──────────┬───────────────┘                            │
│                    │                                             │
│                    ▼                                             │
│         ┌─────────────────────┐                                 │
│         │ NotificationService │                                 │
│         │                     │                                 │
│         │ • getNotifications()│                                 │
│         │ • getUnreadCount()  │                                 │
│         │ • markAsRead()      │                                 │
│         │ • markAllAsRead()   │                                 │
│         │ • registerDevice()  │                                 │
│         └──────────┬──────────┘                                 │
│                    │                                             │
│                    ▼                                             │
│         ┌─────────────────────┐                                 │
│         │    ApiService       │                                 │
│         │                     │                                 │
│         │ • GET /notifications│                                 │
│         │ • PATCH /mark-read  │                                 │
│         │ • POST /devices     │                                 │
│         └──────────┬──────────┘                                 │
│                    │                                             │
└────────────────────┼─────────────────────────────────────────────┘
                     │
                     │ HTTP/HTTPS
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Backend API Server                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  /user/api/notifications/                                        │
│  ├── GET /                    (List notifications)               │
│  ├── GET /{id}/               (Get single notification)          │
│  ├── GET /unread-count/       (Get badge count)                 │
│  ├── PATCH /{id}/mark-read/   (Mark as read)                    │
│  ├── PATCH /read-all/         (Mark all as read)                │
│  └── POST /devices/           (Register FCM token)              │
│                                                                   │
│  ┌──────────────────┐      ┌──────────────────┐                │
│  │   Notification   │      │   DeviceToken    │                │
│  │     Model        │      │     Model        │                │
│  └──────────────────┘      └──────────────────┘                │
│                                                                   │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │   Database    │
                    │   (PostgreSQL)│
                    └───────────────┘
```

## Data Flow

### 1. Loading Notifications
```
HomePage
  └─▶ _loadNotificationCount()
       └─▶ NotificationService.getUnreadCount()
            └─▶ ApiService.get('/notifications/unread-count/')
                 └─▶ Backend API
                      └─▶ Returns: { "count": 5 }
                           └─▶ Update badge on HomePage
```

### 2. Viewing Notifications
```
User taps notification icon
  └─▶ Navigate to NotificationsPage
       └─▶ _loadNotifications()
            └─▶ NotificationService.getNotifications(page: 1)
                 └─▶ ApiService.get('/notifications/?page=1&page_size=20')
                      └─▶ Backend API
                           └─▶ Returns: NotificationListResponse
                                └─▶ Display notifications in list
```

### 3. Marking as Read
```
User taps notification
  └─▶ _markAsRead(notification)
       └─▶ NotificationService.markAsRead(notificationId)
            └─▶ ApiService.patch('/notifications/{id}/mark-read/')
                 └─▶ Backend API
                      └─▶ Update notification.isRead = true
                           └─▶ Update UI
                                └─▶ Decrease badge count
```

### 4. Pagination (Infinite Scroll)
```
User scrolls to bottom
  └─▶ _onScroll() detects near end
       └─▶ _loadMoreNotifications()
            └─▶ NotificationService.getNotifications(page: 2)
                 └─▶ ApiService.get('/notifications/?page=2&page_size=20')
                      └─▶ Backend API
                           └─▶ Returns: More notifications
                                └─▶ Append to existing list
```

## Notification Types & Payloads

### BOOKING_CONFIRMED 🎉
```json
{
  "id": "uuid",
  "title": "Booking Confirmed 🎉",
  "message": "Your table at Pizza Palace has been confirmed...",
  "notification_type": "BOOKING_CONFIRMED",
  "is_read": false,
  "payload": {
    "booking_id": "uuid",
    "restaurant_id": "uuid",
    "booking_date": "2026-03-15T19:30:00Z"
  },
  "created_at": "2026-02-13T10:30:00Z"
}
```

### FAV_DEAL 🔥
```json
{
  "id": "uuid",
  "title": "New Deal Available 🔥",
  "message": "Pizza Palace has launched a new offer: 50% off...",
  "notification_type": "FAV_DEAL",
  "is_read": false,
  "payload": {
    "restaurant_id": "uuid",
    "deal_id": "uuid"
  },
  "created_at": "2026-02-12T14:20:00Z"
}
```

### DEAL_REDEEMED ✅
```json
{
  "id": "uuid",
  "title": "Deal Redeemed ✅",
  "message": "You successfully redeemed the deal at...",
  "notification_type": "DEAL_REDEEMED",
  "is_read": true,
  "payload": {
    "deal_id": "uuid",
    "restaurant_id": "uuid"
  },
  "created_at": "2026-02-11T18:45:00Z"
}
```

### SYSTEM 📢
```json
{
  "id": "uuid",
  "title": "System Announcement 📢",
  "message": "New features available! Check them out...",
  "notification_type": "SYSTEM",
  "is_read": false,
  "payload": {
    "action": "open_features",
    "custom_data": "any"
  },
  "created_at": "2026-02-10T09:00:00Z"
}
```

## UI Components

### Home Page Badge
```
┌──────────────────────────────────────────┐
│  [Logo] Discount Buddy    [Live] [🔔 5] │
│                                           │
│  📍 London ▼              🔍             │
│                                           │
│  🔥 Best Offers  ⭐ Top Rated  📍 Nearest│
└──────────────────────────────────────────┘
```

### Notifications Page
```
┌──────────────────────────────────────────┐
│  ← Notifications        Mark all read    │
├──────────────────────────────────────────┤
│                                           │
│  ┌─────────────────────────────────────┐ │
│  │ 🎉  Booking Confirmed          • ⃝  │ │
│  │     Your table at Pizza Palace...   │ │
│  │     5m ago                          │ │
│  └─────────────────────────────────────┘ │
│                                           │
│  ┌─────────────────────────────────────┐ │
│  │ 🔥  New Deal Available              │ │
│  │     Pizza Palace has launched...    │ │
│  │     2h ago                          │ │
│  └─────────────────────────────────────┘ │
│                                           │
│  ┌─────────────────────────────────────┐ │
│  │ ✅  Deal Redeemed                   │ │
│  │     You successfully redeemed...    │ │
│  │     1d ago                          │ │
│  └─────────────────────────────────────┘ │
│                                           │
└──────────────────────────────────────────┘
```

## State Management

### HomePage State
```dart
int _notificationCount = 0;  // Badge count

// Load on init
_loadNotificationCount()

// Reload when returning from notifications
Navigator.push(...).then((_) => _loadNotificationCount())
```

### NotificationsPage State
```dart
List<NotificationModel> _notifications = [];
int _currentPage = 1;
bool _hasMore = true;
bool _isLoading = true;
bool _isLoadingMore = false;
int _unreadCount = 0;

// Pagination
_onScroll() → _loadMoreNotifications()

// Pull to refresh
RefreshIndicator → _loadNotifications()

// Mark as read
_markAsRead(notification) → Update UI + API call
```

## Error Handling

### Network Errors
```dart
try {
  final notifications = await service.getNotifications();
} catch (e) {
  _showError('Failed to load notifications');
}
```

### Empty States
```dart
if (_notifications.isEmpty) {
  return EmptyStateWidget(
    icon: Icons.notifications_none,
    title: 'No notifications yet',
    subtitle: 'We\'ll notify you when something arrives',
  );
}
```

### Authentication Errors
- Handled by ApiService
- JWT token in Authorization header
- Auto-retry on 401 (if refresh token available)

## Performance Optimizations

1. **Pagination** - Load 20 items at a time
2. **Lazy Loading** - Infinite scroll
3. **Caching** - Local state management
4. **Debouncing** - Scroll event handling
5. **Optimistic Updates** - Update UI before API confirmation
