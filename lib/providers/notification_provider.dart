import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  static final NotificationProvider _instance = NotificationProvider._internal();
  factory NotificationProvider() => _instance;
  NotificationProvider._internal();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasFetched = false;
  bool get hasFetched => _hasFetched;

  final NotificationService _notificationService = NotificationService();

  Future<void> fetchUnreadCount(bool isMerchant) async {
    // Prevent multiple initial fetches unless forcing a refresh
    if (_hasFetched && !isLoading) {
      // Sync with SharedPreferences in case background handler updated it
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedCount = prefs.getInt('unread_notification_count') ?? _unreadCount;
        if (storedCount != _unreadCount) {
          _unreadCount = storedCount;
          notifyListeners();
        }
      } catch (_) {}
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final count = await _notificationService.getUnreadCount(isMerchant: isMerchant);
      _unreadCount = count;
      _hasFetched = true;
      
      // Sync persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_notification_count', count);
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refreshCount(bool isMerchant) async {
    _hasFetched = false;
    await fetchUnreadCount(isMerchant);
  }

  void incrementCount() async {
    _unreadCount++;
    notifyListeners();
    
    // Sync to persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_notification_count', _unreadCount);
    } catch (_) {}
  }

  void resetCount() async {
    _unreadCount = 0;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_notification_count', 0);
    } catch (_) {}
  }
  
  void setCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }
}
