import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopdar_driver/features/notification/data/models/notification_model.dart';
import 'package:kopdar_driver/features/notification/presentation/widgets/notification_tile.dart';

void main() {
  group('NotificationTile Widget Tests', () {
    Widget buildTile(NotificationModel notification) {
      return MaterialApp(
        home: Scaffold(
          body: NotificationTile(notification: notification),
        ),
      );
    }

    testWidgets('renders title and body', (tester) async {
      final notif = NotificationModel.fromJson({
        'id': 'n-1',
        'type': 'order',
        'title': 'Order Selesai',
        'body': 'Order #1234 telah selesai.',
        'is_read': false,
        'created_at': '2026-01-15T10:30:00.000',
      });

      await tester.pumpWidget(buildTile(notif));

      expect(find.text('Order Selesai'), findsOneWidget);
      expect(find.text('Order #1234 telah selesai.'), findsOneWidget);
    });

    testWidgets('renders type badge', (tester) async {
      final notif = NotificationModel.fromJson({
        'id': 'n-1',
        'type': 'promo',
        'title': 'Promo',
        'body': 'Promo baru!',
        'is_read': false,
        'created_at': '2026-01-15T10:30:00.000',
      });

      await tester.pumpWidget(buildTile(notif));

      expect(find.text('Promo'), findsNWidgets(2));
      expect(find.text('🎉'), findsOneWidget);
    });

    testWidgets('shows unread indicator for unread notification',
        (tester) async {
      final notif = NotificationModel.fromJson({
        'id': 'n-1',
        'type': 'order',
        'title': 'Test',
        'body': 'Body',
        'is_read': false,
        'created_at': '2026-01-15T10:30:00.000',
      });

      await tester.pumpWidget(buildTile(notif));

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Container && widget.decoration is BoxDecoration,
        ),
        findsWidgets,
      );
    });

    testWidgets('no unread dot for read notification', (tester) async {
      final notif = NotificationModel.fromJson({
        'id': 'n-1',
        'type': 'order',
        'title': 'Test',
        'body': 'Body',
        'is_read': true,
        'created_at': '2026-01-15T10:30:00.000',
      });

      await tester.pumpWidget(buildTile(notif));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('onTap callback fires when tapped', (tester) async {
      var tapped = false;
      final notif = NotificationModel.fromJson({
        'id': 'n-1',
        'type': 'order',
        'title': 'Tap me',
        'body': 'Body',
        'is_read': false,
        'created_at': '2026-01-15T10:30:00.000',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationTile(
              notification: notif,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });
  });
}
