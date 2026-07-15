import 'package:flutter/material.dart';

import 'package:kopdar_driver/features/notification/data/datasources/notification_remote_ds.dart';
import 'package:kopdar_driver/features/notification/data/models/notification_model.dart';

enum NotificationStatus { initial, loading, loaded, error }

/// Provider for the Notification feature.
class NotificationProvider extends ChangeNotifier {
  final NotificationRemoteDataSource _dataSource;

  NotificationProvider({NotificationRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? NotificationRemoteDataSource();

  NotificationStatus _status = NotificationStatus.initial;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  String? _errorMessage;
  bool _hasMore = true;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  NotificationStatus get status => _status;
  List<NotificationModel> get notifications =>
      List<NotificationModel>.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == NotificationStatus.loading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  Map<String, List<NotificationModel>> get groupedByDate {
    final grouped = <String, List<NotificationModel>>{};
    for (final notification in _notifications) {
      grouped
          .putIfAbsent(_dateKey(notification.createdAt), () => [])
          .add(notification);
    }
    return grouped;
  }

  String _dateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Hari Ini';
    if (difference == 1) return 'Kemarin';
    if (difference > 1 && difference < 7) return '$difference Hari Lalu';
    return '${date.day}/${date.month}/${date.year}';
  }

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
      await fetchUnreadCount();
    } catch (_) {
      _status = NotificationStatus.error;
      _errorMessage = 'Gagal memuat notifikasi.';
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    final nextPage = _currentPage + 1;
    try {
      final more = await _dataSource.getNotifications(page: nextPage);
      _notifications.addAll(more);
      _currentPage = nextPage;
      _hasMore = more.length >= 20;
    } catch (_) {
      _errorMessage = 'Gagal memuat notifikasi berikutnya.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _dataSource.getUnreadCount();
      notifyListeners();
    } catch (_) {
      // Unread count is supplementary; keep the current value on failure.
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((notification) => notification.id == id);
    if (index == -1 || _notifications[index].isRead) return;

    final previous = _notifications[index];
    _notifications[index] = previous.copyWith(isRead: true);
    _unreadCount = (_unreadCount - 1).clamp(0, 9999).toInt();
    notifyListeners();

    try {
      await _dataSource.markAsRead(id);
    } catch (_) {
      final currentIndex =
          _notifications.indexWhere((notification) => notification.id == id);
      if (currentIndex != -1) {
        _notifications[currentIndex] = previous;
        _unreadCount++;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final backup = List<NotificationModel>.from(_notifications);
    final previousUnreadCount = _unreadCount;

    _notifications =
        _notifications.map((notification) => notification.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _dataSource.markAllAsRead();
    } catch (_) {
      _notifications = backup;
      _unreadCount = previousUnreadCount;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((notification) => notification.id == id);
    if (index == -1) return;

    final removed = _notifications.removeAt(index);
    if (!removed.isRead) {
      _unreadCount = (_unreadCount - 1).clamp(0, 9999).toInt();
    }
    notifyListeners();

    try {
      await _dataSource.deleteNotification(id);
    } catch (_) {
      final restoreIndex = index.clamp(0, _notifications.length).toInt();
      _notifications.insert(restoreIndex, removed);
      if (!removed.isRead) _unreadCount++;
      notifyListeners();
    }
  }

  Future<void> deleteAll() async {
    final backup = List<NotificationModel>.from(_notifications);
    final previousUnreadCount = _unreadCount;

    _notifications = [];
    _unreadCount = 0;
    notifyListeners();

    try {
      await _dataSource.deleteAll();
    } catch (_) {
      _notifications = backup;
      _unreadCount = previousUnreadCount;
      notifyListeners();
    }
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) _unreadCount++;
    notifyListeners();
  }
}
