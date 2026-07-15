import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/transaction_provider.dart';
import '../widgets/platform_chip.dart';
import '../widgets/transaction_list_item.dart';

/// List of income transactions with filters.
class IncomeHistoryPage extends StatefulWidget {
  const IncomeHistoryPage({super.key});

  @override
  State<IncomeHistoryPage> createState() => _IncomeHistoryPageState();
}

class _IncomeHistoryPageState extends State<IncomeHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransactionProvider>();
      provider.setTypeFilter('income');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Riwayat Penghasilan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // ── Header with total ──
              _HeaderTotal(provider: provider),

              // ── Period filter tabs ──
              _PeriodTabs(provider: provider),

              // ── Platform filter chips ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: PlatformChipList(
                  selected: provider.platformFilter,
                  onSelected: (name) {
                    if (name == 'Semua') {
                      provider.setPlatformFilter(null);
                    } else {
                      provider.setPlatformFilter(name);
                    }
                  },
                  showAll: true,
                ),
              ),

              // ── Transaction list ──
              Expanded(
                child: _TransactionList(provider: provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/income/add'),
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }
}

class _HeaderTotal extends StatelessWidget {
  final TransactionProvider provider;

  const _HeaderTotal({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Penghasilan',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(provider.totalIncome.toInt()),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${provider.transactions.where((t) => t.type == 'income').length} transaksi',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  final TransactionProvider provider;

  const _PeriodTabs({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: TransactionFilter.values.map((filter) {
          final isSelected = provider.periodFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.setPeriodFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.white : Colors.transparent,
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
                  _filterLabel(filter),
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

  String _filterLabel(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.today:
        return 'Hari Ini';
      case TransactionFilter.thisWeek:
        return 'Minggu Ini';
      case TransactionFilter.thisMonth:
        return 'Bulan Ini';
    }
  }
}

class _TransactionList extends StatelessWidget {
  final TransactionProvider provider;

  const _TransactionList({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.transactions.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (_, __) => const TransactionListItemShimmer(),
      );
    }

    if (provider.status == TransactionStatus.error &&
        provider.transactions.isEmpty) {
      return _ErrorState(
        message: provider.errorMessage ?? 'Terjadi kesalahan',
        onRetry: () => provider.fetchTransactions(refresh: true),
      );
    }

    if (provider.transactions.isEmpty) {
      return _EmptyState(period: provider.periodFilter);
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchTransactions(refresh: true),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.transactions.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.transactions.length) {
            // Load more trigger
            provider.loadMore();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            );
          }

          final tx = provider.transactions[index];
          return TransactionListItem(
            transaction: tx,
            onTap: () => context.push('/income/${tx.id}'),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final TransactionFilter period;

  const _EmptyState({required this.period});

  @override
  Widget build(BuildContext context) {
    String message;
    switch (period) {
      case TransactionFilter.today:
        message = 'Belum ada penghasilan hari ini';
        break;
      case TransactionFilter.thisWeek:
        message = 'Belum ada penghasilan minggu ini';
        break;
      case TransactionFilter.thisMonth:
        message = 'Belum ada penghasilan bulan ini';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.gray500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ketuk + untuk menambah penghasilan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gray400,
                  ),
            ),
          ],
        ),
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
