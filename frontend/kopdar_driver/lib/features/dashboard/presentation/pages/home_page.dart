import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../finance/presentation/providers/finance_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/income_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/alert_card.dart';
import '../widgets/dana_darurat_card.dart';
import '../widgets/recent_transactions.dart';
import '../../../notification/presentation/widgets/notification_badge.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

/// Main home dashboard screen for KopDar drivers.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.dailySummary == null) {
          return const _LoadingState();
        }

        if (provider.status == DashboardStatus.error &&
            provider.dailySummary == null) {
          return _ErrorState(
            message: provider.errorMessage ?? 'Terjadi kesalahan',
            onRetry: provider.fetchDashboard,
          );
        }

        return _DashboardContent(provider: provider);
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardProvider provider;

  const _DashboardContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final summary = provider.dailySummary!;

    return RefreshIndicator(
      onRefresh: provider.fetchDashboard,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ── Green header ──
          SliverToBoxAdapter(
            child: _Header(
              driverName: provider.driverName,
            ),
          ),

          // ── Body content (overlaps header) ──
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Income Card
                    IncomeCard(
                      amount: summary.income,
                      orderCount: summary.orderCount,
                      hours: summary.hours,
                      avgPerOrder: summary.avgPerOrder,
                      changePercent: summary.changePercent,
                    ),
                    const SizedBox(height: 12),

                    // Hourly Rate Mini Card
                    const _HourlyRateMiniCard(),
                    const SizedBox(height: 20),

                    // Quick Actions
                    QuickActionsGrid(
                      onTabungan: () => context.push('/savings'),
                      onAsuransi: () => context.push('/insurance'),
                      onKomunitas: () {},
                      onKeuangan: () => context.push('/keuangan'),
                      onRiwayat: () => context.push('/ride/history'),
                      onRewards: () => context.push('/rewards'),
                    ),
                    const SizedBox(height: 20),

                    // Alert Card (conditional)
                    if (provider.alertMessage != null) ...[
                      AlertCard(
                        message: provider.alertMessage!,
                        type: provider.alertType,
                        onDismiss: provider.dismissAlert,
                        onTap: () => context.push('/pinjol'),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Dana Darurat
                    if (provider.danaDarurat != null)
                      DanaDaruratCard(
                        currentAmount: provider.danaDarurat!.currentAmount,
                        targetAmount: provider.danaDarurat!.targetAmount,
                        dailyAmount: provider.danaDarurat!.dailyAmount,
                      ),
                    const SizedBox(height: 20),

                    // Recent Transactions
                    RecentTransactions(
                      transactions: provider.recentTransactions,
                      onViewAll: () => context.push('/income/history'),
                    ),
                    const SizedBox(height: 80), // padding for FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini card showing hourly rate on the dashboard.
class _HourlyRateMiniCard extends StatefulWidget {
  const _HourlyRateMiniCard();

  @override
  State<_HourlyRateMiniCard> createState() => _HourlyRateMiniCardState();
}

class _HourlyRateMiniCardState extends State<_HourlyRateMiniCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FinanceProvider>();
      if (provider.hourlyRate == null) {
        provider.fetchHourlyRate('today');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final data = provider.hourlyRate;

        return GestureDetector(
          onTap: () => context.push('/finance/hourly-rate'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text('⏱️', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarif Per Jam',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (data != null)
                        Text(
                          '${_formatRate(data.hourlyRate)} ${data.trendEmoji}${_formatPercent(data.percentDiff)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: data.isAboveAverage
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        )
                      else if (provider.isLoadingHourlyRate)
                        Container(
                          width: 100,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.gray200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      else
                        Text(
                          'Ketuk untuk lihat detail',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.gray400,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.gray400,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatRate(double rate) {
    return 'Rp ${_formatNumber(rate.toInt())}/jam';
  }

  String _formatPercent(double value) {
    final percent = (value * 100).round();
    if (percent >= 0) return '+$percent%';
    return '$percent%';
  }

  String _formatNumber(int number) {
    final s = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

/// Green gradient header with greeting, driver name, and avatar.
class _Header extends StatelessWidget {
  final String driverName;

  const _Header({required this.driverName});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 16,
        left: 20,
        right: 20,
        bottom: 60, // extra space for overlap
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Greeting + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()} 👋',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  driverName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),

          // Notification bell
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: NotificationBadge(
                  count: context.watch<NotificationProvider>().unreadCount,
                  size: 22,
                  iconColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              driverName.isNotEmpty ? driverName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Memuat dashboard...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😵', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
