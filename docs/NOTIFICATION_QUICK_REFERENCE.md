# Notification System - Quick Reference Guide

## 🚀 Quick Start

### 1. Import the Service
```dart
import 'package:discount_buddy/services/notification_service.dart';
import 'package:discount_buddy/models/notification.dart';
```

### 2. Initialize the Service
```dart
final NotificationService _notificationService = NotificationService();
```

### 3. Get Unread Count (for Badge)
```dart
Future<void> _loadNotificationCount() async {
  try {
    final count = await _notificationService.getUnreadCount();
    setState(() => _notificationCount = count);
  } catch (e) {
    // Handle error
  }
}
```

### 4. Load Notifications
```dart
Future<void> _loadNotifications() async {
  try {
    final response = await _notificationService.getNotifications(
      page: 1,
      pageSize: 20,
    );
    
    setState(() {
      _notifications = response.results;
      _hasMore = response.next != null;
    });
  } catch (e) {
    // Handle error
  }
}
```

### 5. Mark as Read
```dart
Future<void> _markAsRead(String notificationId) async {
  try {
    await _notificationService.markAsRead(notificationId);
    // Update UI
  } catch (e) {
    // Handle error
  }
}
```

## 📱 UI Components

### Notification Badge (Already Implemented in HomePage)
```dart
// Badge shows on notification icon
if (_notificationCount > 0)
  Container(
    child: Text(
      _notificationCount > 99 ? '99+' : _notificationCount.toString(),
      style: TextStyle(fontSize: 9, color: Colors.white),
    ),
  )
```

### Navigate to Notifications Page
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NotificationsPage(),
  ),
);
```

## 🔔 Notification Types

| Type | Icon | Color | Use Case |
|------|------|-------|----------|
| `BOOKING_CONFIRMED` | 🎉 | Green | Booking status changes |
| `FAV_DEAL` | 🔥 | Orange | New deal at favorite restaurant |
| `DEAL_REDEEMED` | ✅ | Purple | Deal successfully redeemed |
| `SYSTEM` | 📢 | Blue | System announcements |

## 🎨 Styling

### Colors
```dart
static const Color buddyOrange = Color(0xFFFF7A00);
static const Color buddyPink = Color(0xFFFF2D83);
static const Color buddyPurple = Color(0xFF7C3AED);
static const Color buddyYellow = Color(0xFFFFB100);
```

### Gradients
```dart
const List<Color> buddyGradient = [
  buddyPink,
  buddyPurple,
  buddyOrange,
  buddyYellow,
];
```

## 🔧 Common Tasks

### Refresh Badge Count
```dart
// Call this when:
// - App resumes
// - User marks notification as read
// - User returns from notifications page

_loadNotificationCount();
```

### Implement Pull-to-Refresh
```dart
RefreshIndicator(
  onRefresh: () async {
    await _loadNotifications();
    await _loadNotificationCount();
  },
  child: ListView(...),
)
```

### Implement Pagination
```dart
ScrollController _scrollController = ScrollController();

@override
void initState() {
  super.initState();
  _scrollController.addListener(_onScroll);
}

void _onScroll() {
  if (_scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent - 200 &&
      !_isLoadingMore && _hasMore) {
    _loadMoreNotifications();
  }
}

Future<void> _loadMoreNotifications() async {
  setState(() => _isLoadingMore = true);
  
  final response = await _notificationService.getNotifications(
    page: _currentPage + 1,
    pageSize: 20,
  );
  
  setState(() {
    _notifications.addAll(response.results);
    _currentPage++;
    _hasMore = response.next != null;
    _isLoadingMore = false;
  });
}
```

## 🔐 Authentication

All API calls automatically include JWT token from `ApiService`:
```dart
// No need to manually add auth headers
// ApiService handles this automatically
final response = await _notificationService.getNotifications();
```

## ⚠️ Error Handling

### Network Errors
```dart
try {
  await _notificationService.getNotifications();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to load notifications')),
  );
}
```

### Empty State
```dart
if (_notifications.isEmpty) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.notifications_none, size: 60),
        SizedBox(height: 16),
        Text('No notifications yet'),
      ],
    ),
  );
}
```

## 📊 API Response Examples

### Get Unread Count
```json
{
  "count": 5
}
```

### Get Notifications
```json
{
  "count": 45,
  "next": "http://api.example.com/notifications/?page=2",
  "previous": null,
  "results": [
    {
      "id": "uuid",
      "title": "Booking Confirmed 🎉",
      "message": "Your table at Pizza Palace...",
      "notification_type": "BOOKING_CONFIRMED",
      "is_read": false,
      "payload": {
        "booking_id": "uuid",
        "restaurant_id": "uuid"
      },
      "created_at": "2026-02-13T10:30:00Z"
    }
  ]
}
```

### Mark as Read Response
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

### Mark All as Read Response
```json
{
  "success": true,
  "count": 5,
  "message": "5 notifications marked as read"
}
```

## 🧪 Testing

### Test Notification Count
```dart
test('should load notification count', () async {
  final service = NotificationService();
  final count = await service.getUnreadCount();
  expect(count, isA<int>());
});
```

### Test Mark as Read
```dart
test('should mark notification as read', () async {
  final service = NotificationService();
  await service.markAsRead('notification-id');
  // Verify no exception thrown
});
```

## 🎯 Best Practices

1. **Always handle errors gracefully**
   ```dart
   try {
     await service.getNotifications();
   } catch (e) {
     // Show user-friendly error message
   }
   ```

2. **Update badge count after actions**
   ```dart
   await service.markAsRead(id);
   _loadNotificationCount(); // Refresh badge
   ```

3. **Use pagination for large lists**
   ```dart
   // Load 20 items at a time
   service.getNotifications(page: 1, pageSize: 20);
   ```

4. **Implement pull-to-refresh**
   ```dart
   RefreshIndicator(
     onRefresh: _loadNotifications,
     child: ListView(...),
   )
   ```

5. **Show loading states**
   ```dart
   if (_isLoading) {
     return CircularProgressIndicator();
   }
   ```

## 🔮 Future Enhancements

### Firebase Cloud Messaging (FCM)
```dart
// 1. Add dependencies to pubspec.yaml
dependencies:
  firebase_core: ^latest
  firebase_messaging: ^latest

// 2. Initialize Firebase
await Firebase.initializeApp();

// 3. Get FCM token
final token = await FirebaseMessaging.instance.getToken();

// 4. Register with backend
await _notificationService.registerDeviceToken(
  token: token!,
  deviceType: 'android', // or 'ios'
);

// 5. Handle foreground messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Show in-app notification
  _loadNotifications();
  _loadNotificationCount();
});

// 6. Handle notification taps
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Navigate to specific screen based on payload
});
```

### Deep Linking
```dart
void _handleNotificationTap(NotificationModel notification) {
  switch (notification.notificationType) {
    case NotificationType.bookingConfirmed:
      final bookingId = notification.payload?['booking_id'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingDetailsPage(id: bookingId),
        ),
      );
      break;
    
    case NotificationType.favDeal:
      final restaurantId = notification.payload?['restaurant_id'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailsPage(id: restaurantId),
        ),
      );
      break;
  }
}
```

## 📞 Support

For issues or questions:
1. Check `NOTIFICATION_API_REFERENCE.md` for API details
2. Review `NOTIFICATION_ARCHITECTURE.md` for system design
3. See `NOTIFICATION_IMPLEMENTATION_SUMMARY.md` for overview

## ✅ Checklist

- [x] Notification models created
- [x] Notification service implemented
- [x] Notifications page created
- [x] Home page badge added
- [x] API integration complete
- [ ] Firebase FCM configured (optional)
- [ ] Push notifications tested (optional)
- [ ] Deep linking implemented (optional)
