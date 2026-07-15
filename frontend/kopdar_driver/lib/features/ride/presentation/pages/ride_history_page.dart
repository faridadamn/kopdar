import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/ride_model.dart';
import '../providers/ride_provider.dart';
import '../widgets/ride_card.dart';

/// Ride/Order history page with filters and stats.
class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  String _selectedPlatform = 'all';
  String _selectedStatus = 'all';
  String _selectedPeriod = 'today';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideProvider>().fetchRides();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('📦 Riwayat Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Consumer<RideProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.rides.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.status == RideStatus.error && provider.rides.isEmpty) {
            return _ErrorState(onRetry: provider.fetchRides);
          }

          final filtered = _applyFilters(provider.rides);

          return RefreshIndicator(
            onRefresh: provider.fetchRides,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Stats summary ──
                _StatsSummary(rides: filtered),
                const SizedBox(height: 16),

                // ── Active filters ──
                if (_selectedPlatform != 'all' ||
                    _selectedStatus != 'all' ||
                    _selectedPeriod != 'today')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (_selectedPlatform != 'all')
                          _FilterChip(
                            label: _platformName(_selectedPlatform),
                            onRemove: () =>
                                setState(() => _selectedPlatform = 'all'),
                          ),
                        if (_selectedStatus != 'all')
                          _FilterChip(
                            label: _statusName(_selectedStatus),
                            onRemove: () =>
                                setState(() => _selectedStatus = 'all'),
                          ),
                        if (_selectedPeriod != 'today')
                          _FilterChip(
                            label: _periodName(_selectedPeriod),
                            onRemove: () =>
                                setState(() => _selectedPeriod = 'today'),
                          ),
                      ],
                    ),
                  ),

                // ── Ride list ──
                if (filtered.isEmpty)
                  _EmptyState()
                else
                  ...filtered.map(
                    (ride) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RideCard(
                        ride: ride,
                        onTap: () =>
                            context.push('/ride/detail/${ride.id}'),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  List<RideModel> _applyFilters(List<RideModel> rides) {
    var filtered = rides;

    if (_selectedPlatform != 'all') {
      filtered =
          filtered.where((r) => r.platform == _selectedPlatform).toList();
    }
    if (_selectedStatus != 'all') {
      filtered =
          filtered.where((r) => r.status == _selectedStatus).toList();
    }

    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        filtered = filtered
            .where((r) =>
                r.createdAt.year == now.year &&
                r.createdAt.month == now.month &&
                r.createdAt.day == now.day)
            .toList();
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered =
            filtered.where((r) => r.createdAt.isAfter(weekAgo)).toList();
      case 'month':
        filtered = filtered
            .where((r) =>
                r.createdAt.year == now.year &&
                r.createdAt.month == now.month)
            .toList();
    }

    return filtered;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Platform
              Text('Platform',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['all', 'grab', 'gojek', 'shopee', 'maxim']
                    .map((p) => ChoiceChip(
                          label: Text(_platformName(p)),
                          selected: _selectedPlatform == p,
                          onSelected: (_) {
                            setSheetState(() => _selectedPlatform = p);
                            setState(() {});
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Period
              Text('Periode',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['today', 'week', 'month', 'all']
                    .map((p) => ChoiceChip(
                          label: Text(_periodName(p)),
                          selected: _selectedPeriod == p,
                          onSelected: (_) {
                            setSheetState(() => _selectedPeriod = p);
                            setState(() {});
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Terapkan Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _platformName(String p) {
    switch (p) {
      case 'grab':
        return 'Grab';
      case 'gojek':
        return 'Gojek';
      case 'shopee':
        return 'Shopee Food';
      case 'maxim':
        return 'Maxim';
      case 'all':
        return 'Semua';
      default:
        return p;
    }
  }

  String _statusName(String s) {
    switch (s) {
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Semua';
    }
  }

  String _periodName(String p) {
    switch (p) {
      case 'today':
        return 'Hari Ini';
      case 'week':
        return '7 Hari';
      case 'month':
        return 'Bulan Ini';
      case 'all':
        return 'Semua';
      default:
        return p;
    }
  }
}

class _StatsSummary extends StatelessWidget {
  final List<RideModel> rides;

  const _StatsSummary({required this.rides});

  @override
  Widget build(BuildContext context) {
    final totalEarnings = rides.fold(0, (sum, r) => sum + r.earnings);
    final totalDistance = rides.fold(0, (sum, r) => sum + r.distance);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '${rides.length}',
            label: 'Order',
            icon: '📦',
          ),
          Container(width: 1, height: 36, color: Colors.white24),
          _StatItem(
            value: Formatters.currencyCompact(totalEarnings),
            label: 'Pendapatan',
            icon: '💰',
          ),
          Container(width: 1, height: 36, color: Colors.white24),
          _StatItem(
            value: '${(totalDistance / 1000).toStringAsFixed(1)}km',
            label: 'Jarak',
            icon: '🛣️',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final String icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: AppColors.primaryBg,
      labelStyle: const TextStyle(color: AppColors.primary),
      deleteIconColor: AppColors.primary,
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Belum ada order',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Order yang sudah selesai akan muncul di sini.',
              style: TextStyle(color: AppColors.gray500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😵', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('Gagal memuat riwayat order.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
