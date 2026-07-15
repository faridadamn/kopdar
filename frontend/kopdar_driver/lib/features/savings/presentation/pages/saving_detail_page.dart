import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/saving_model.dart';
import '../providers/saving_provider.dart';
import '../widgets/progress_ring.dart';

/// Detail page for a single savings goal.
class SavingDetailPage extends StatefulWidget {
  final String id;

  const SavingDetailPage({super.key, required this.id});

  @override
  State<SavingDetailPage> createState() => _SavingDetailPageState();
}

class _SavingDetailPageState extends State<SavingDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavingProvider>().fetchGoalDetail(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Detail Tabungan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<SavingProvider>(
        builder: (context, provider, _) {
          if (provider.detailStatus == SavingStatus.loading &&
              provider.selectedGoal == null) {
            return const _LoadingState();
          }

          if (provider.detailStatus == SavingStatus.error &&
              provider.selectedGoal == null) {
            return _ErrorState(
              message: provider.errorMessage ?? 'Terjadi kesalahan',
              onRetry: () => provider.fetchGoalDetail(widget.id),
            );
          }

          final goal = provider.selectedGoal;
          if (goal == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () => provider.fetchGoalDetail(widget.id),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  _GoalHeader(goal: goal),
                  const SizedBox(height: 20),

                  // ── Stats ──
                  _StatsRow(goal: goal),
                  const SizedBox(height: 20),

                  // ── Action buttons ──
                  _ActionButtons(
                    goal: goal,
                    onDeposit: () => _showDepositDialog(context, provider),
                    onWithdraw: () =>
                        _showWithdrawDialog(context, provider, goal),
                    onTogglePause: () => _togglePause(context, provider, goal),
                  ),
                  const SizedBox(height: 24),

                  // ── Transaction history ──
                  Text(
                    'Riwayat Transaksi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (goal.recentTransactions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Belum ada transaksi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.gray500,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ...goal.recentTransactions.map(
                      (tx) => _TransactionItem(transaction: tx),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _togglePause(
    BuildContext context,
    SavingProvider provider,
    SavingModel goal,
  ) async {
    bool success;
    if (goal.isActive) {
      success = await provider.pauseGoal(goal.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-save dijeda ⏸️'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } else {
      success = await provider.resumeGoal(goal.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-save dilanjutkan ▶️'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _showDepositDialog(
      BuildContext context, SavingProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Setor Manual'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Masukkan nominal',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(
                  controller.text.replaceAll(RegExp(r'[^\d]'), ''));
              if (amount != null && amount > 0) {
                Navigator.pop(ctx);
                final success = await provider.deposit(
                  widget.id,
                  amount,
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Berhasil setor ${Formatters.currency(amount.toInt())} ✅',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Setor'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(
    BuildContext context,
    SavingProvider provider,
    SavingModel goal,
  ) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final isEmergencyFund =
        goal.goalName.toLowerCase().contains('darurat');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Tarik Dana'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEmergencyFund)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.danger.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ini dana darurat! Hanya tarik jika benar-benar mendesak.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Masukkan nominal',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Catatan (opsional)',
              ),
            ),
          ],
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
              final amount = double.tryParse(amountController.text
                  .replaceAll(RegExp(r'[^\d]'), ''));
              if (amount != null && amount > 0) {
                // Double-confirm for emergency fund
                if (isEmergencyFund) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx2) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Konfirmasi'),
                      content: Text(
                        'Yakin mau tarik ${Formatters.currency(amount.toInt())} '
                        'dari Dana Darurat?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx2, false),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                          ),
                          onPressed: () => Navigator.pop(ctx2, true),
                          child: const Text('Ya, Tarik'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                }

                Navigator.pop(ctx);
                final success = await provider.withdraw(
                  widget.id,
                  amount,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Berhasil tarik ${Formatters.currency(amount.toInt())}',
                      ),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              }
            },
            child: const Text('Tarik Dana'),
          ),
        ],
      ),
    );
  }
}

/// Header with icon, name, status badge, and big number.
class _GoalHeader extends StatelessWidget {
  final SavingModel goal;

  const _GoalHeader({required this.goal});

  Color get _statusColor {
    switch (goal.status) {
      case 'active':
        return AppColors.success;
      case 'paused':
        return AppColors.warning;
      case 'completed':
        return AppColors.primary;
      default:
        return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Icon + name + status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(goal.goalIcon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Text(
                goal.goalName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  goal.statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Big number
          Text(
            Formatters.currency(goal.currentAmount.toInt()),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'dari ${Formatters.currency(goal.targetAmount.toInt())}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Progress ring
          ProgressRing(
            progress: goal.progress,
            size: 80,
            strokeWidth: 7,
            color: Colors.white,
            backgroundColor: Colors.white24,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats row: Daily amount, Auto-save, Estimated days.
class _StatsRow extends StatelessWidget {
  final SavingModel goal;

  const _StatsRow({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: '💰',
            label: 'Setor/Hari',
            value: Formatters.currency(goal.dailyAmount.toInt()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: goal.autoSave ? '🔄' : '⏸️',
            label: 'Auto-Save',
            value: goal.autoSave ? 'Aktif' : 'Nonaktif',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: '📅',
            label: 'Estimasi',
            value: '${goal.estimatedDays} hari',
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
            style: TextStyle(fontSize: 11, color: AppColors.gray500),
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

/// Action buttons: Setor Manual | Tarik Dana | Pause/Resume.
class _ActionButtons extends StatelessWidget {
  final SavingModel goal;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onTogglePause;

  const _ActionButtons({
    required this.goal,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: goal.isActive ? onDeposit : null,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Setor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onWithdraw,
            icon: const Icon(Icons.remove_rounded, size: 18),
            label: const Text('Tarik'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTogglePause,
            icon: Icon(
              goal.isActive
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 18,
            ),
            label: Text(goal.isActive ? 'Jeda' : 'Lanjut'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  goal.isActive ? AppColors.gray600 : AppColors.success,
              side: BorderSide(
                color: goal.isActive
                    ? AppColors.gray400
                    : AppColors.success,
              ),
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Single transaction item in the history list.
class _TransactionItem extends StatelessWidget {
  final SavingTransaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction.isDeposit;
    final color = isDeposit ? AppColors.success : AppColors.danger;
    final icon = isDeposit ? Icons.add_rounded : Icons.remove_rounded;
    final prefix = isDeposit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeposit ? 'Setor' : 'Tarik',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                if (transaction.notes != null &&
                    transaction.notes!.isNotEmpty)
                  Text(
                    transaction.notes!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gray500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${Formatters.currency(transaction.amount.toInt())}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                Formatters.relativeTime(transaction.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.gray500,
                ),
              ),
            ],
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
