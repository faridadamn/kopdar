import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/pinjol_model.dart';
import '../providers/pinjol_provider.dart';
import '../widgets/risk_badge.dart';
import '../widgets/payoff_simulator.dart';

/// Detail page for a single loan.
class PinjolDetailPage extends StatefulWidget {
  final String id;

  const PinjolDetailPage({super.key, required this.id});

  @override
  State<PinjolDetailPage> createState() => _PinjolDetailPageState();
}

class _PinjolDetailPageState extends State<PinjolDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PinjolProvider>();
      provider.fetchLoanDetail(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Detail Pinjaman'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Consumer<PinjolProvider>(
            builder: (context, provider, _) {
              if (provider.selectedLoan == null) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete(context, provider);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: AppColors.danger, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Hapus',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<PinjolProvider>(
        builder: (context, provider, _) {
          if (provider.detailStatus == PinjolStatus.loading &&
              provider.selectedLoan == null) {
            return const _LoadingState();
          }

          if (provider.detailStatus == PinjolStatus.error &&
              provider.selectedLoan == null) {
            return _ErrorState(
              message: provider.errorMessage ?? 'Terjadi kesalahan',
              onRetry: () => provider.fetchLoanDetail(widget.id),
            );
          }

          final loan = provider.selectedLoan;
          if (loan == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                _LoanHeader(loan: loan),
                const SizedBox(height: 20),

                // ── Stats grid ──
                _StatsGrid(loan: loan),
                const SizedBox(height: 20),

                // ── Payoff simulator ──
                PayoffSimulator(
                  currentMonths: provider.simulationMonths,
                  simulation: provider.simulation,
                  onMonthsChanged: (months) =>
                      provider.setSimulationMonths(months),
                  maxMonths:
                      loan.monthsRemaining > 0 ? loan.monthsRemaining : 24,
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, PinjolProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Hapus Pinjaman?'),
        content: const Text(
          'Data pinjaman akan dihapus. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteLoan(widget.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pinjaman dihapus'),
                    backgroundColor: AppColors.gray700,
                  ),
                );
                context.pop();
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

/// Header with app name and risk badge.
class _LoanHeader extends StatelessWidget {
  final PinjolModel loan;

  const _LoanHeader({required this.loan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: loan.isDanger
              ? [AppColors.danger, AppColors.danger.withOpacity(0.8)]
              : loan.isWarning
                  ? [AppColors.warning, AppColors.warning.withOpacity(0.8)]
                  : [AppColors.accent, AppColors.accent.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (loan.isDanger
                    ? AppColors.danger
                    : loan.isWarning
                        ? AppColors.warning
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💳', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(
                loan.appName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${loan.riskEmoji} ${loan.riskLabel}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            Formatters.currency(loan.outstandingAmount.toInt()),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'sisa outstanding',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats grid: Principal, Interest Rate, Installment, Months Remaining.
class _StatsGrid extends StatelessWidget {
  final PinjolModel loan;

  const _StatsGrid({required this.loan});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _StatTile(
          icon: '💰',
          label: 'Pokok Pinjaman',
          value: Formatters.currency(loan.principal.toInt()),
        ),
        _StatTile(
          icon: '📈',
          label: 'Bunga/Bulan',
          value: '${loan.interestRate.toStringAsFixed(1)}%',
          valueColor: loan.isDanger ? AppColors.danger : AppColors.gray900,
        ),
        _StatTile(
          icon: '📅',
          label: 'Cicilan/Bulan',
          value: Formatters.currency(loan.monthlyInstallment.toInt()),
        ),
        _StatTile(
          icon: '⏳',
          label: 'Sisa Bulan',
          value: '${loan.monthsRemaining} bulan',
        ),
        _StatTile(
          icon: '💸',
          label: 'Bunga Terbayar',
          value: Formatters.currency(loan.totalPaidInterest.toInt()),
          valueColor: AppColors.danger,
        ),
        _StatTile(
          icon: '📊',
          label: 'Total Bunga',
          value:
              Formatters.currency(loan.totalInterestIfFullTerm.toInt()),
          valueColor: AppColors.danger,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.gray500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.gray900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            'Memuat detail...',
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
