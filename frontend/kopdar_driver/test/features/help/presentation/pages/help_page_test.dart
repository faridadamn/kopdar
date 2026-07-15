import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopdar_driver/features/help/presentation/pages/help_page.dart';

void main() {
  group('HelpPage Widget Tests', () {
    Widget buildPage() {
      return const MaterialApp(home: HelpPage());
    }

    Future<void> scrollTo(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
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
      expect(find.text('Cari jawaban atau hubungi kami langsung.'), findsOneWidget);
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
      expect(answer, findsNothing);

      await tester.tap(find.text('Bagaimana cara menambah poin?'));
      await tester.pumpAndSettle();
      expect(answer, findsOneWidget);
    });

    testWidgets('renders feedback section', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final feedbackTitle = find.text('Kirim Masukan');
      await scrollTo(tester, feedbackTitle.first);
      expect(feedbackTitle, findsNWidgets(2));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders app version info', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final version = find.text('KopDar v1.0.0');
      await scrollTo(tester, version);
      expect(version, findsOneWidget);
      expect(find.text('Koperasi Digital untuk Gig Worker Indonesia'), findsOneWidget);
    });

    testWidgets('feedback button shows snackbar after submit', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final field = find.byType(TextField);
      await scrollTo(tester, field);
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
