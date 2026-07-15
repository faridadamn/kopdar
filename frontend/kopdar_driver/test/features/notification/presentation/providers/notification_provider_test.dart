import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kopdar_driver/features/notification/presentation/providers/notification_provider.dart';
import 'package:kopdar_driver/features/notification/data/datasources/notification_remote_ds.dart';
import 'package:kopdar_driver/features/notification/data/models/notification_model.dart';

class MockNotificationRemoteDataSource extends Mock
    implements NotificationRemoteDataSource {}

void main() {
  late NotificationProvider provider;
  late MockNotificationRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockNotificationRemoteDataSource();
    provider = NotificationProvider(dataSource: mockDataSource);
  });

  NotificationModel _makeNotif({
    String id = 'n-1',
    String type = 'order',
    bool isRead = false,
    String title = 'Test Notification',
  }) {
    return NotificationModel.fromJson({
      'id': id,
      'type': type,
      'title': title,
      'body': 'Test body',
      'is_read': isRead,
      'created_at': '2026-01-15T10:30:00.000',
    });
  }

  group('NotificationProvider — Initial State', () {
    test('initial state is correct', () {
      expect(provider.status, NotificationStatus.initial);
      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
      expect(provider.hasMore, isTrue);
    });
  });

  group('NotificationProvider — Fetch', () {
    test('fetchNotifications success populates list', () async {
      final notifs = [
        _makeNotif(id: 'n-1', title: 'Order selesai'),
        _makeNotif(id: 'n-2', type: 'promo', title: 'Promo baru'),
      ];

      when(() => mockDataSource.getNotifications(page: 1))
          .thenAnswer((_) async => notifs);
      when(() => mockDataSource.getUnreadCount()).thenAnswer((_) async => 2);

      await provider.fetchNotifications();

      expect(provider.status, NotificationStatus.loaded);
      expect(provider.notifications, hasLength(2));
      expect(provider.unreadCount, 2);
    });

    test('fetchNotifications failure sets error state', () async {
      when(() => mockDataSource.getNotifications(page: 1))
          .thenThrow(Exception('network'));

      await provider.fetchNotifications();

      expect(provider.status, NotificationStatus.error);
      expect(provider.errorMessage, contains('Gagal'));
    });
  });

  group('NotificationProvider — Mark as Read', () {
    test('markAsRead optimistically updates notification', () async {
      final notifs = [
        _makeNotif(id: 'n-1', isRead: false),
      ];

      when(() => mockDataSource.getNotifications(page: 1))
          .thenAnswer((_) async => notifs);
      when(() => mockDataSource.getUnreadCount()).thenAnswer((_) async => 1);
      when(() => mockDataSource.markAsRead('n-1'))
          .thenAnswer((_) async {});

      await provider.fetchNotifications();
      expect(provider.unreadCount, 1);

      await provider.markAsRead('n-1');

      expect(provider.notifications[0].isRead, isTrue);
      expect(provider.unreadCount, 0);
      verify(() => mockDataSource.markAsRead('n-1')).called(1);
    });
  });

  group('NotificationProvider — Mark All as Read', () {
    test('markAllAsRead sets all to read', () async {
      final notifs = [
        _makeNotif(id: 'n-1', isRead: false),
        _makeNotif(id: 'n-2', isRead: false),
        _makeNotif(id: 'n-3', isRead: true),
      ];

      when(() => mockDataSource.getNotifications(page: 1))
          .thenAnswer((_) async => notifs);
      when(() => mockDataSource.getUnreadCount()).thenAnswer((_) async => 2);
      when(() => mockDataSource.markAllAsRead()).thenAnswer((_) async {});

      await provider.fetchNotifications();
      await provider.markAllAsRead();

      expect(provider.unreadCount, 0);
      expect(provider.notifications.every((n) => n.isRead), isTrue);
    });
  });

  group('NotificationProvider — Delete', () {
    test('deleteNotification removes from list', () async {
      final notifs = [
        _makeNotif(id: 'n-1', isRead: false),
        _makeNotif(id: 'n-2', isRead: true),
      ];

      when(() => mockDataSource.getNotifications(page: 1))
          .thenAnswer((_) async => notifs);
      when(() => mockDataSource.getUnreadCount()).thenAnswer((_) async => 1);
      when(() => mockDataSource.deleteNotification('n-1'))
          .thenAnswer((_) async {});

      await provider.fetchNotifications();
      await provider.deleteNotification('n-1');

      expect(provider.notifications, hasLength(1));
      expect(provider.notifications[0].id, 'n-2');
      expect(provider.unreadCount, 0);
    });
  });

  group('NotificationProvider — Add from Push', () {
    test('addNotification inserts at beginning', () async {
      when(() => mockDataSource.getNotifications(page: 1))
          .thenAnswer((_) async => [_makeNotif(id: 'n-1')]);
      when(() => mockDataSource.getUnreadCount()).thenAnswer((_) async => 1);

      await provider.fetchNotifications();

      final newNotif = _makeNotif(id: 'n-new', title: 'Push notification');
      provider.addNotification(newNotif);

      expect(provider.notifications, hasLength(2));
      expect(provider.notifications[0].id, 'n-new');
      expect(provider.unreadCount, 2);
    });
  });

  group('NotificationProvider — Grouped by Date', () {
    test('groups notifications by date key', () async {
      final notifs = [
        _makeNotif(id: 'n-1'),
      ];

      when(() => mockDataSource.getNotifications(page: 1))
          .thenAnswer((_) async => notifs);
      when(() => mockDataSource.getUnreadCount()).thenAnswer((_) async => 1);

      await provider.fetchNotifications();

      final grouped = provider.groupedByDate;
      expect(grouped, isNotEmpty);
      expect(grouped.containsKey('Hari Ini') ||
          grouped.containsKey('Kemarin') ||
          grouped.keys.any((k) => k.contains('/')), isTrue);
    });
  });
}
