import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../income/presentation/providers/transaction_provider.dart';
import '../../../income/presentation/widgets/transaction_list_item.dart';

/// Expense categories with emoji icons.
const _expenseCategories = [
  {'key': null, 'label': 'Semua', 'emoji': '📋'},
  {'key': 'bensin', 'label': 'Bensin', 'emoji': '⛽'},
  {'key': 'makan', 'label': 'Makan', 'emoji': '🍚'},
  {'key': 'angsuran', 'label': 'Angsuran', 'emoji': '🏍️'},
  {'key': 'servis', 'label': 'Servis', 'emoji': '🔧'},
  {'key': 'pulsa', 'label': 'Pulsa', 'emoji': '📱'},
  {'key': 'parkir', 'label': 'Parkir', 'emoji': '🅿️'},
  {'key': 'kesehatan', 'label': 'Kesehatan', 'emoji': '💊'},
  {'key': 'lainnya', 'label': 'Lainnya', 'emoji': '📦'},
];

/// Dedicated expense history page with category filters and date grouping.
class ExpenseHistoryPage extends StatefulWidget {
  const ExpenseHistoryPage({super.key});

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransactionProvider>();
      provider.setTypeFilter('expense');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Riwayat Pengeluaran'),
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

              // ── Category filter chips ──
              _CategoryChips(
                selected: _selectedCategory,
                onSelected: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),

              // ── Expense list grouped by date ──
              Expanded(
                child: _ExpenseList(
                  provider: provider,
                  categoryFilter: _selectedCategory,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.danger,
        onPressed: () => context.push('/expense/add'),
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }
}

/// Header showing total expense for the selected period.
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
          colors: [AppColors.danger, Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Pengeluaran',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(provider.totalExpense.toInt()),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${provider.transactions.where((t) => t.type == 'expense').length} transaksi',
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

/// Period filter tabs: Hari Ini | Minggu Ini | Bulan Ini.
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
                  _filterLabel(filter),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.danger
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

/// Horizontal scrollable category filter chips.
class _CategoryChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _expenseCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _expenseCategories[index];
          final key = cat['key'] as String?;
          final isSelected = selected == key;
          final emoji = cat['emoji'] as String;
          final label = cat['label'] as String;

          return GestureDetector(
            onTap: () => onSelected(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.danger : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.danger
                      : AppColors.gray300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Expense list grouped by date with filtering.
class _ExpenseList extends StatelessWidget {
  final TransactionProvider provider;
  final String? categoryFilter;

  const _ExpenseList({
    required this.provider,
    required this.categoryFilter,
  });

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

    // Filter by category if selected
    var expenses =
        provider.transactions.where((t) => t.type == 'expense').toList();

    if (categoryFilter != null) {
      expenses = expenses
          .where(
              (t) => t.category.toLowerCase() == categoryFilter!.toLowerCase())
          .toList();
    }

    if (expenses.isEmpty) {
      return _EmptyState(period: provider.periodFilter);
    }

    // Group by date
    final grouped = <String, List<dynamic>>{};
    for (final tx in expenses) {
      final dateKey = Formatters.date(tx.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }

    final dateKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () => provider.fetchTransactions(refresh: true),
      color: AppColors.danger,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dateKeys.length,
        itemBuilder: (context, index) {
          final dateKey = dateKeys[index];
          final txns = grouped[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  children: [
                    Text(
                      dateKey,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.gray200,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.currency(
                        txns.fold<double>(
                                0, (sum, t) => sum + (t.amount as double))
                            .toInt(),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),

              // Transactions for this date
              ...txns.map((tx) => TransactionListItem(
                    transaction: tx,
                    onTap: () => context.push('/income/${tx.id}'),
                  )),
            ],
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
        message = 'Belum ada pengeluaran hari ini';
        break;
      case TransactionFilter.thisWeek:
        message = 'Belum ada pengeluaran minggu ini';
        break;
      case TransactionFilter.thisMonth:
        message = 'Belum ada pengeluaran bulan ini';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
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
              'Ketuk + untuk mencatat pengeluaran',
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
