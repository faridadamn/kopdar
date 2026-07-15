import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/finance_provider.dart';
import '../widgets/hourly_rate_chart.dart';

/// Hourly rate calculator screen with period selector, stats, and daily chart.
class HourlyRatePage extends StatefulWidget {
  const HourlyRatePage({super.key});

  @override
  State<HourlyRatePage> createState() => _HourlyRatePageState();
}

class _HourlyRatePageState extends State<HourlyRatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().fetchHourlyRate('today');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Tarif Per Jam'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingHourlyRate && provider.hourlyRate == null) {
            return const _LoadingState();
          }

          if (provider.hourlyRateStatus == FinanceStatus.error &&
              provider.hourlyRate == null) {
            return _ErrorState(
              message: provider.errorMessage ?? 'Terjadi kesalahan',
              onRetry: () =>
                  provider.fetchHourlyRate(provider.hourlyRatePeriod),
            );
          }

          final data = provider.hourlyRate;
          if (data == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () =>
                provider.fetchHourlyRate(provider.hourlyRatePeriod),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Period selector ──
                  _PeriodSelector(
                    selected: provider.hourlyRatePeriod,
                    onSelected: (period) =>
                        provider.fetchHourlyRate(period),
                  ),
                  const SizedBox(height: 24),

                  // ── Big hourly rate display ──
                  _BigRateDisplay(data: data),
                  const SizedBox(height: 24),

                  // ── Stats row ──
                  _StatsRow(data: data),
                  const SizedBox(height: 24),

                  // ── Daily breakdown chart ──
                  Text(
                    'Breakdown Harian',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  HourlyRateChart(
                    dailyBreakdown: data.dailyBreakdown,
                    zoneAverage: data.zoneAverage,
                  ),
                  const SizedBox(height: 24),

                  // ── Insight card ──
                  _InsightCard(data: data),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Period selector: Hari Ini | Minggu Ini | Bulan Ini.
class _PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _PeriodSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('today', 'Hari Ini'),
      ('week', 'Minggu Ini'),
      ('month', 'Bulan Ini'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = selected == opt.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  opt.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.gray500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Big display of hourly rate with trend indicator.
class _BigRateDisplay extends StatelessWidget {
  final dynamic data; // HourlyRateModel

  const _BigRateDisplay({required this.data});

  @override
  Widget build(BuildContext context) {
    final trendColor = data.isAboveAverage
        ? AppColors.success
        : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Tarif Per Jam',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${Formatters.currency(data.hourlyRate.toInt())}/jam',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Comparison badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${data.trendEmoji} ${Formatters.percentage(data.percentDiff)} dari rata-rata zona',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats row: Total Hours | Total Profit | Avg Rate.
class _StatsRow extends StatelessWidget {
  final dynamic data; // HourlyRateModel

  const _StatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: '⏱️',
            label: 'Total Jam',
            value: Formatters.hours(data.totalHours),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: '💰',
            label: 'Total Profit',
            value: Formatters.currencyCompact(data.totalProfit.toInt()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: '📈',
            label: 'Rata-rata',
            value: '${Formatters.currencyCompact(data.hourlyRate.toInt())}/jam',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Insight card at the bottom.
class _InsightCard extends StatelessWidget {
  final dynamic data; // HourlyRateModel

  const _InsightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.insight.isEmpty) return const SizedBox.shrink();

    final isAbove = data.isAboveAverage;
    final bgColor =
        isAbove ? AppColors.primaryBg : AppColors.accentLight;
    final iconColor =
        isAbove ? AppColors.primary : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAbove ? '💡' : '⚠️',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kamu dapat ${Formatters.currency(data.hourlyRate.toInt())}/jam. '
                  'Rata-rata zona ${Formatters.currency(data.zoneAverage.toInt())}/jam.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gray700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Menghitung tarif per jam...',
            style: TextStyle(color: AppColors.gray500),
          ),
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
