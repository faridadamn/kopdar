import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopdar_driver/features/help/presentation/pages/help_page.dart';

void main() {
  group('HelpPage Widget Tests', () {
    Widget buildPage() => const MaterialApp(home: HelpPage());

    Future<void> scrollDown(WidgetTester tester, {double offset = 700}) async {
      await tester.drag(find.byType(ListView), Offset(0, -offset));
      await tester.pumpAndSettle();
    }

    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('❓ Bantuan'), findsOneWidget);
    });

    testWidgets('renders header with help text', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('Ada yang bisa kami bantu?'), findsOneWidget);
      expect(
        find.text('Cari jawaban atau hubungi kami langsung.'),
        findsOneWidget,
      );
    });

    testWidgets('renders contact cards', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Telepon'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders FAQ section', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('Pertanyaan Umum (FAQ)'), findsOneWidget);
      expect(find.text('Bagaimana cara menambah poin?'), findsOneWidget);
      expect(find.text('Bagaimana cara naik level?'), findsOneWidget);
    });

    testWidgets('FAQ tile expands on tap', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final answer = find.textContaining('Kamu bisa mendapatkan poin dengan:');
      final textBefore = tester.widget<Text>(answer);
      expect(textBefore.data, contains('Menyelesaikan order'));

      await tester.tap(find.text('Bagaimana cara menambah poin?'));
      await tester.pumpAndSettle();

      expect(answer, findsOneWidget);
      expect(tester.getSize(answer).height, greaterThan(0));
    });

    testWidgets('renders feedback section', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await scrollDown(tester, offset: 1200);

      expect(find.text('Kirim Masukan'), findsNWidgets(2));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders app version info', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await scrollDown(tester, offset: 1800);

      expect(find.text('KopDar v1.0.0'), findsOneWidget);
      expect(
        find.text('Koperasi Digital untuk Gig Worker Indonesia'),
        findsOneWidget,
      );
    });

    testWidgets('feedback button shows snackbar after submit', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await scrollDown(tester, offset: 1300);

      final field = find.byType(TextField);
      await tester.enterText(field, 'Aplikasi bagus!');

      final submitButton = find.widgetWithText(ElevatedButton, 'Kirim Masukan');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        find.text('Terima kasih! Masukan kamu sangat berharga. 🙏'),
        findsOneWidget,
      );
    });
  });
}
