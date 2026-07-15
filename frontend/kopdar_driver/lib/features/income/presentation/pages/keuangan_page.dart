import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/platform_chip.dart';
import '../widgets/transaction_list_item.dart';

/// Financial dashboard with tabs: Penghasilan, Pengeluaran, Ringkasan.
///
/// Replaces the previous "Coming Soon" placeholder.
class KeuanganPage extends StatefulWidget {
  const KeuanganPage({super.key});

  @override
  State<KeuanganPage> createState() => _KeuanganPageState();
}

class _KeuanganPageState extends State<KeuanganPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TransactionProvider _provider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<TransactionProvider>();
      _provider.setTypeFilter(null); // Load all
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final provider = context.read<TransactionProvider>();
    switch (_tabController.index) {
      case 0:
        provider.setTypeFilter('income');
        break;
      case 1:
        provider.setTypeFilter('expense');
        break;
      case 2:
        // Summary tab — no filter change needed
        provider.fetchSummary('month');
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Keuangan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Penghasilan'),
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Ringkasan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IncomeTab(),
          _ExpenseTab(),
          _SummaryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          // Show add options
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => _AddOptionsSheet(),
          );
        },
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }
}

/// ── Income Tab ──
class _IncomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Period filter
            _PeriodSelector(provider: provider),

            // Platform filter
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

            // Income total
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Penghasilan',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray600,
                        ),
                      ),
                      Text(
                        Formatters.currency(provider.totalIncome.toInt()),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // List
            Expanded(child: _TransactionListContent(provider: provider)),
          ],
        );
      },
    );
  }
}

/// ── Expense Tab ──
class _ExpenseTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Period filter
            _PeriodSelector(provider: provider),

            // Expense total
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_down_rounded,
                      color: AppColors.danger),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pengeluaran',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray600,
                        ),
                      ),
                      Text(
                        Formatters.currency(provider.totalExpense.toInt()),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // List
            Expanded(child: _TransactionListContent(provider: provider)),
          ],
        );
      },
    );
  }
}

/// ── Summary Tab ──
class _SummaryTab extends StatefulWidget {
  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab> {
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchSummary(_selectedPeriod);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selector
              _PeriodChips(
                selected: _selectedPeriod,
                onSelected: (period) {
                  setState(() => _selectedPeriod = period);
                  provider.fetchSummary(period);
                },
              ),
              const SizedBox(height: 20),

              // Stat cards
              Row(
                children: [
                  Expanded(
                    child: SummaryCard.income(
                        amount: provider.totalIncome),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard.expense(
                        amount: provider.totalExpense),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SummaryCard.profit(amount: provider.profit),
              const SizedBox(height: 24),

              // Bar chart
              Text(
                'Pengeluaran per Kategori',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              _BarChart(provider: provider),
              const SizedBox(height: 24),

              // Platform breakdown (income)
              if (provider.transactions
                  .where((t) => t.type == 'income')
                  .isNotEmpty) ...[
                Text(
                  'Penghasilan per Platform',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                _PlatformBreakdown(provider: provider),
                const SizedBox(height: 24),
              ],

              // Category breakdown (expense)
              if (provider.transactions
                  .where((t) => t.type == 'expense')
                  .isNotEmpty) ...[
                Text(
                  'Pengeluaran per Kategori',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                _CategoryBreakdown(provider: provider),
              ],

              const SizedBox(height: 24),

              // ── Hourly Rate Card ──
              _HourlyRateCard(),
              const SizedBox(height: 16),

              // ── Action buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/finance/insights'),
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text('Lihat Insight'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/finance/export'),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Export Data'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80), // FAB padding
            ],
          ),
        );
      },
    );
  }
}

/// ── Period filter selector ──
class _PeriodSelector extends StatelessWidget {
  final TransactionProvider provider;

  const _PeriodSelector({required this.provider});

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
                  _label(filter),
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

  String _label(TransactionFilter filter) {
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

/// ── Period chips for summary tab ──
class _PeriodChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _PeriodChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('week', 'Minggu Ini'),
      ('month', 'Bulan Ini'),
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelected(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : AppColors.gray300,
                ),
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? AppColors.white : AppColors.gray600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// ── Transaction list content ──
class _TransactionListContent extends StatelessWidget {
  final TransactionProvider provider;

  const _TransactionListContent({required this.provider});

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😵', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage ?? 'Terjadi kesalahan',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => provider.fetchTransactions(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Belum ada transaksi',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.gray500,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchTransactions(refresh: true),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount:
            provider.transactions.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.transactions.length) {
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

/// ── Simple bar chart for expense categories ──
class _BarChart extends StatelessWidget {
  final TransactionProvider provider;

  const _BarChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    // Group expenses by category
    final expenses =
        provider.transactions.where((t) => t.type == 'expense').toList();
    final categoryTotals = <String, double>{};
    for (final tx in expenses) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0) + tx.amount;
    }

    if (categoryTotals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('📊', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'Belum ada data pengeluaran',
              style: TextStyle(color: AppColors.gray500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final maxAmount =
        categoryTotals.values.reduce((a, b) => a > b ? a : b);
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: entries.map((entry) {
          final ratio = maxAmount > 0 ? entry.value / maxAmount : 0.0;
          final emoji = _categoryEmoji(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    Formatters.currency(entry.value.toInt()),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'bensin':
        return '⛽';
      case 'makan':
        return '🍚';
      case 'angsuran':
        return '🏍️';
      case 'servis':
        return '🔧';
      case 'pulsa':
        return '📱';
      case 'parkir':
        return '🅿️';
      case 'kesehatan':
        return '💊';
      default:
        return '📦';
    }
  }
}

/// ── Platform breakdown for income ──
class _PlatformBreakdown extends StatelessWidget {
  final TransactionProvider provider;

  const _PlatformBreakdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    final incomes =
        provider.transactions.where((t) => t.type == 'income').toList();
    final platformTotals = <String, double>{};
    for (final tx in incomes) {
      final key = tx.platform ?? 'Lainnya';
      platformTotals[key] = (platformTotals[key] ?? 0) + tx.netAmount;
    }

    if (platformTotals.isEmpty) return const SizedBox.shrink();

    final entries = platformTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  _platformEmoji(entry.key),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  Formatters.currency(entry.value.toInt()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _platformEmoji(String platform) {
    switch (platform.toLowerCase()) {
      case 'gojek':
        return '🛵';
      case 'grab':
        return '🚗';
      case 'shopeefood':
        return '🍔';
      case 'maxim':
        return '🚕';
      case 'indrive':
        return '🚙';
      case 'cash':
        return '💵';
      default:
        return '📋';
    }
  }
}

/// ── Category breakdown for expenses ──
class _CategoryBreakdown extends StatelessWidget {
  final TransactionProvider provider;

  const _CategoryBreakdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    final expenses =
        provider.transactions.where((t) => t.type == 'expense').toList();
    final categoryTotals = <String, double>{};
    for (final tx in expenses) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0) + tx.amount;
    }

    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  _categoryEmoji(entry.key),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  Formatters.currency(entry.value.toInt()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'bensin':
        return '⛽';
      case 'makan':
        return '🍚';
      case 'angsuran':
        return '🏍️';
      case 'servis':
        return '🔧';
      case 'pulsa':
        return '📱';
      case 'parkir':
        return '🅿️';
      case 'kesehatan':
        return '💊';
      default:
        return '📦';
    }
  }
}

/// Hourly rate display card for the Ringkasan tab.
class _HourlyRateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/finance/hourly-rate'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('⏱️', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarif Per Jam',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Lihat detail tarif per jam kamu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for choosing income vs expense
class _AddOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tambah Transaksi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('💰', style: TextStyle(fontSize: 22)),
              ),
              title: const Text('Penghasilan'),
              subtitle: const Text('Tambah penghasilan dari platform'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/income/add');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('💸', style: TextStyle(fontSize: 22)),
              ),
              title: const Text('Pengeluaran'),
              subtitle: const Text('Catat pengeluaran harian'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/expense/add');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
