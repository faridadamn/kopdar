import 'package:flutter_test/flutter_test.dart';
import 'package:kopdar_driver/features/notification/data/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 'n-1',
        'type': 'order',
        'title': 'Order Selesai',
        'body': 'Order #1234 telah selesai. Pendapatan: Rp 25.000',
        'image_url': 'https://example.com/img.jpg',
        'data': {'type': 'income', 'id': 'tx-123'},
        'is_read': false,
        'created_at': '2026-01-15T10:30:00.000',
      };

      final n = NotificationModel.fromJson(json);

      expect(n.id, 'n-1');
      expect(n.type, 'order');
      expect(n.title, 'Order Selesai');
      expect(n.body, contains('Rp 25.000'));
      expect(n.imageUrl, 'https://example.com/img.jpg');
      expect(n.data, isNotNull);
      expect(n.data!['type'], 'income');
      expect(n.isRead, isFalse);
    });

    test('fromJson handles missing fields with defaults', () {
      final n = NotificationModel.fromJson({});

      expect(n.id, '');
      expect(n.type, 'system');
      expect(n.title, '');
      expect(n.body, '');
      expect(n.imageUrl, isNull);
      expect(n.data, isNull);
      expect(n.isRead, isFalse);
    });

    test('copyWith creates new instance with overrides', () {
      final original = NotificationModel.fromJson({
        'id': 'n-1',
        'is_read': false,
      });

      final updated = original.copyWith(isRead: true);

      expect(updated.isRead, isTrue);
      expect(updated.id, 'n-1'); // unchanged
    });

    test('typeEmoji returns correct emoji for each type', () {
      expect(NotificationModel.fromJson({'type': 'order'}).typeEmoji, '📦');
      expect(NotificationModel.fromJson({'type': 'promo'}).typeEmoji, '🎉');
      expect(NotificationModel.fromJson({'type': 'community'}).typeEmoji, '👥');
      expect(NotificationModel.fromJson({'type': 'sos'}).typeEmoji, '🚨');
      expect(NotificationModel.fromJson({'type': 'referral'}).typeEmoji, '🤝');
      expect(NotificationModel.fromJson({'type': 'savings'}).typeEmoji, '🐷');
      expect(NotificationModel.fromJson({'type': 'insurance'}).typeEmoji, '🛡️');
      expect(NotificationModel.fromJson({'type': 'payment'}).typeEmoji, '💰');
      expect(NotificationModel.fromJson({'type': 'level'}).typeEmoji, '🏆');
      expect(NotificationModel.fromJson({'type': 'unknown'}).typeEmoji, '🔔');
    });

    test('typeLabel returns Bahasa label', () {
      expect(NotificationModel.fromJson({'type': 'order'}).typeLabel, 'Order');
      expect(NotificationModel.fromJson({'type': 'promo'}).typeLabel, 'Promo');
      expect(
          NotificationModel.fromJson({'type': 'community'}).typeLabel, 'Komunitas');
      expect(NotificationModel.fromJson({'type': 'sos'}).typeLabel, 'Darurat');
    });

    test('route returns correct deep link path', () {
      expect(
        NotificationModel.fromJson({
          'data': {'type': 'income', 'id': 'tx-1'}
        }).route,
        '/income/tx-1',
      );
      expect(
        NotificationModel.fromJson({
          'data': {'type': 'saving', 'id': 'sv-1'}
        }).route,
        '/savings/sv-1',
      );
      expect(
        NotificationModel.fromJson({
          'data': {'type': 'community', 'id': 'post-1'}
        }).route,
        '/community/post-1',
      );
      expect(
        NotificationModel.fromJson({
          'data': {'type': 'emergency'}
        }).route,
        '/emergency/sos',
      );
      expect(
        NotificationModel.fromJson({
          'data': {'type': 'referral'}
        }).route,
        '/profile/referral',
      );
    });

    test('route returns null when no data', () {
      expect(NotificationModel.fromJson({}).route, isNull);
    });

    test('route returns null for unknown type', () {
      expect(
        NotificationModel.fromJson({
          'data': {'type': 'unknown_type'}
        }).route,
        isNull,
      );
    });
  });
}
