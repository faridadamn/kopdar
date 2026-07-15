import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';
import '../data/datasources/notification_remote_ds.dart';

enum NotificationStatus { initial, loading, loaded, error }

/// Provider for the Notification feature.
class NotificationProvider extends ChangeNotifier {
  final NotificationRemoteDataSource _dataSource;

  NotificationProvider({NotificationRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? NotificationRemoteDataSource();

  // ── State ──
  NotificationStatus _status = NotificationStatus.initial;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  String? _errorMessage;
  bool _hasMore = true;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  // ── Getters ──
  NotificationStatus get status => _status;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == NotificationStatus.loading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  /// Grouped notifications by date.
  Map<String, List<NotificationModel>> get groupedByDate {
    final map = <String, List<NotificationModel>>{};
    for (final n in _notifications) {
      final key = _dateKey(n.createdAt);
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  String _dateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Hari Ini';
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return '${diff} Hari Lalu';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ── Actions ──

  /// Fetch notifications (first page).
  Future<void> fetchNotifications() async {
    _status = NotificationStatus.loading;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      _notifications = await _dataSource.getNotifications(page: 1);
      _status = NotificationStatus.loaded;
      _hasMore = _notifications.length >= 20;
      notifyListeners();

      // Also fetch unread count
      fetchUnreadCount();
    } catch (e) {
      _status = NotificationStatus.error;
      _errorMessage = 'Gagal memuat notifikasi.';
      notifyListeners();
    }
  }

  /// Load more notifications (pagination).
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final more = await _dataSource.getNotifications(page: _currentPage);
      _notifications.addAll(more);
      _hasMore = more.length >= 20;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _currentPage--;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Fetch unread count.
  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _dataSource.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String id) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      notifyListeners();
    }

    try {
      await _dataSource.markAsRead(id);
    } catch (_) {
      // Revert on error
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        _unreadCount++;
        notifyListeners();
      }
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    // Optimistic update
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _dataSource.markAllAsRead();
    } catch (_) {
      // Refetch on error
      fetchNotifications();
    }
  }

  /// Delete a single notification.
  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    final removed = index != -1 ? _notifications[index] : null;

    // Optimistic remove
    if (index != -1) {
      _notifications.removeAt(index);
      if (removed != null && !removed.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      }
      notifyListeners();
    }

    try {
      await _dataSource.deleteNotification(id);
    } catch (_) {
      // Revert on error
      if (index != -1 && removed != null) {
        _notifications.insert(index, removed);
        if (!removed.isRead) _unreadCount++;
        notifyListeners();
      }
    }
  }

  /// Delete all notifications.
  Future<void> deleteAll() async {
    final backup = List<NotificationModel>.from(_notifications);
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();

    try {
      await _dataSource.deleteAll();
    } catch (_) {
      _notifications = backup;
      notifyListeners();
    }
  }

  /// Add a notification (from FCM push).
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) _unreadCount++;
    notifyListeners();
  }
}
