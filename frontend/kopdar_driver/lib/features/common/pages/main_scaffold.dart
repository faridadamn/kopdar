import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../dashboard/presentation/pages/home_page.dart';
import '../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../notification/presentation/providers/notification_provider.dart';
import '../../keuangan/keuangan_page.dart';
import '../../komunitas/komunitas_page.dart';
import '../../profile/presentation/pages/profil_page.dart';
import '../widgets/bottom_nav.dart';

/// NOTE: DashboardProvider is registered in main.dart via MultiProvider.
/// We call fetchDashboard() here on first build.

/// Root scaffold hosting the 4 main tabs with bottom navigation.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Trigger initial dashboard load (once)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DashboardProvider>();
      if (provider.status == DashboardStatus.initial) {
        provider.fetchDashboard();
      }
      // Fetch unread notification count
      context.read<NotificationProvider>().fetchUnreadCount();
    });

    return Scaffold(
      body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            HomePage(),
            KeuanganPage(),
            KomunitasPage(),
            ProfilePage(),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  // TODO: Implement SOS
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('SOS — Fitur segera hadir!'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                },
                backgroundColor: AppColors.danger,
                child: const Text('🆘', style: TextStyle(fontSize: 24)),
              )
            : null,
        bottomNavigationBar: KopDarBottomNav(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      );
  }
}
