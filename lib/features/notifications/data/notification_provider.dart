import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:discount_buddy/features/notifications/data/notifications_repository_impl.dart';
import 'package:discount_buddy/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:discount_buddy/features/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  static final NotificationProvider _instance = NotificationProvider._internal();
  factory NotificationProvider() => _instance;
  NotificationProvider._internal() {
    _repository = NotificationsRepositoryImpl();
    _getUnreadCountUseCase = GetUnreadCountUseCase(_repository);
  }

  late NotificationsRepository _repository;
  late GetUnreadCountUseCase _getUnreadCountUseCase;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasFetched = false;
  bool get hasFetched => _hasFetched;

  /// Avoids "setState/markNeedsBuild during build" when callers run from [initState].
  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }

  Future<void> fetchUnreadCount(bool isMerchant) async {
    // Prevent multiple initial fetches unless forcing a refresh
    if (_hasFetched && !isLoading) {
      // Sync with SharedPreferences in case background handler updated it
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedCount = prefs.getInt('unread_notification_count') ?? _unreadCount;
        if (storedCount != _unreadCount) {
          _unreadCount = storedCount;
          _safeNotifyListeners();
        }
      } catch (_) {}
      return;
    }

    _isLoading = true;
    _safeNotifyListeners();

    try {
      final result = await _getUnreadCountUseCase(isMerchant: isMerchant);
      result.fold(
        onSuccess: (count) {
          _unreadCount = count;
          _hasFetched = true;
          
          // Sync persistent storage
          SharedPreferences.getInstance().then((prefs) {
            prefs.setInt('unread_notification_count', count);
          }).catchError((_) {});
        },
        onError: (failure) {
          debugPrint('Error fetching unread count: ${failure.message}');
        },
      );
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void refreshCount(bool isMerchant) async {
    _hasFetched = false;
    await fetchUnreadCount(isMerchant);
  }

  void incrementCount() async {
    _unreadCount++;
    _safeNotifyListeners();
    
    // Sync to persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_notification_count', _unreadCount);
    } catch (_) {}
  }

  void resetCount() async {
    _unreadCount = 0;
    _safeNotifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_notification_count', 0);
    } catch (_) {}
  }
  
  void setCount(int count) {
    _unreadCount = count;
    _safeNotifyListeners();
  }
}
