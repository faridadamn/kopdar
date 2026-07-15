import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../providers/pinjol_provider.dart';
import '../widgets/pinjol_card.dart';
import '../widgets/debt_ratio_indicator.dart';

/// Main Pinjol Radar dashboard page.
class PinjolPage extends StatefulWidget {
  const PinjolPage({super.key});

  @override
  State<PinjolPage> createState() => _PinjolPageState();
}

class _PinjolPageState extends State<PinjolPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PinjolProvider>().fetchLoans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('📊 Pinjol Radar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<PinjolProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.loans.isEmpty) {
            return const _LoadingState();
          }

          if (provider.status == PinjolStatus.error &&
              provider.loans.isEmpty) {
            return _ErrorState(
              message: provider.errorMessage ?? 'Terjadi kesalahan',
              onRetry: provider.fetchLoans,
            );
          }

          if (provider.loans.isEmpty) {
            return _EmptyState(
              onAdd: () => context.push('/pinjol/add'),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchLoans,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Summary card ──
                _SummaryCard(provider: provider),
                const SizedBox(height: 16),

                // ── Risk summary ──
                _RiskSummaryRow(provider: provider),
                const SizedBox(height: 16),

                // ── Recommendations ──
                ...provider.recommendations.map(
                  (rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        rec,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                if (provider.recommendations.isNotEmpty)
                  const SizedBox(height: 8),

                // ── Loan list ──
                Text(
                  'Pinjaman Aktif',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                ...provider.loans.map(
                  (loan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PinjolCard(
                      loan: loan,
                      onTap: () => context.push('/pinjol/${loan.id}'),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pinjol/add'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Pinjaman',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Summary card with total outstanding, monthly installment, and debt ratio.
class _SummaryCard extends StatelessWidget {
  final PinjolProvider provider;

  const _SummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: provider.isDebtRatioWarning
              ? [AppColors.danger, AppColors.danger.withOpacity(0.8)]
              : [AppColors.accent, AppColors.accent.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (provider.isDebtRatioWarning
                    ? AppColors.danger
                    : AppColors.accent)
                .withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Outstanding',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.currency(
                          provider.totalOutstanding.toInt()),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cicilan/bulan',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      Formatters.currency(
                          provider.totalMonthlyInstallment.toInt()),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              DebtRatioIndicator(
                ratio: provider.debtToIncomeRatio,
                size: 80,
              ),
            ],
          ),
          if (provider.isDebtRatioWarning) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rasio cicilan ${(provider.debtToIncomeRatio * 100).round()}% — di atas batas aman 30%!',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Risk summary row: 🟢 X aman, 🟡 X waspada, 🔴 X berisiko.
class _RiskSummaryRow extends StatelessWidget {
  final PinjolProvider provider;

  const _RiskSummaryRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RiskChip(
          emoji: '🟢',
          label: 'Aman',
          count: provider.safeCount,
          color: AppColors.success,
        ),
        const SizedBox(width: 8),
        _RiskChip(
          emoji: '🟡',
          label: 'Waspada',
          count: provider.warningCount,
          color: AppColors.warning,
        ),
        const SizedBox(width: 8),
        _RiskChip(
          emoji: '🔴',
          label: 'Berisiko',
          count: provider.dangerCount,
          color: AppColors.danger,
        ),
      ],
    );
  }
}

class _RiskChip extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final Color color;

  const _RiskChip({
    required this.emoji,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              '$count $label',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            'Menganalisis pinjaman...',
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Tidak ada pinjaman aktif',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bagus! Pertahankan kondisi keuanganmu.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Pinjaman'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
