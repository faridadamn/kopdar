import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopdar_driver/features/help/presentation/pages/help_page.dart';

void main() {
  group('HelpPage Widget Tests', () {
    Widget buildPage() {
      return const MaterialApp(
        home: HelpPage(),
      );
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
      expect(find.text('Cari jawaban atau hubungi kami langsung.'),
          findsOneWidget);
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
      expect(
        find.text('Bagaimana cara menambah poin?'),
        findsOneWidget,
      );
      expect(
        find.text('Bagaimana cara naik level?'),
        findsOneWidget,
      );
    });

    testWidgets('FAQ tile expands on tap', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // Initially, answer should not be visible
      expect(
        find.text('Kamu bisa mendapatkan poin dengan:'),
        findsNothing,
      );

      // Tap the first FAQ
      await tester.tap(find.text('Bagaimana cara menambah poin?'));
      await tester.pumpAndSettle();

      // Now answer should be visible
      expect(
        find.text('Kamu bisa mendapatkan poin dengan:'),
        findsOneWidget,
      );
    });

    testWidgets('renders feedback section', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Kirim Masukan'), findsOneWidget);
      expect(find.text('Kirim Masukan'), findsWidgets); // button too
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders app version info', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('KopDar v1.0.0'), findsOneWidget);
      expect(
        find.text('Koperasi Digital untuk Gig Worker Indonesia'),
        findsOneWidget,
      );
    });

    testWidgets('feedback button shows snackbar after submit',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // Enter feedback text
      await tester.enterText(
          find.byType(TextField), 'Aplikasi bagus!');
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.text('Kirim Masukan').last);
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(
        find.text('Terima kasih! Masukan kamu sangat berharga. 🙏'),
        findsOneWidget,
      );
    });
  });
}
