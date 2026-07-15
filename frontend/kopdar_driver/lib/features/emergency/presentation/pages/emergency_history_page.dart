import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../providers/emergency_provider.dart';
import '../../data/models/emergency_model.dart';

/// List of past emergencies with status badges.
class EmergencyHistoryPage extends StatefulWidget {
  const EmergencyHistoryPage({super.key});

  @override
  State<EmergencyHistoryPage> createState() => _EmergencyHistoryPageState();
}

class _EmergencyHistoryPageState extends State<EmergencyHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyProvider>().fetchHistory(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('📋 Riwayat Darurat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<EmergencyProvider>(
        builder: (context, provider, _) {
          if (provider.historyStatus == EmergencyStatus.loading &&
              provider.history.isEmpty) {
            return const _LoadingState();
          }

          if (provider.historyStatus == EmergencyStatus.error &&
              provider.history.isEmpty) {
            return _ErrorState(
              message: provider.errorMessage ?? 'Terjadi kesalahan',
              onRetry: () => provider.fetchHistory(refresh: true),
            );
          }

          if (provider.history.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchHistory(refresh: true),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final emergency = provider.history[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EmergencyHistoryCard(emergency: emergency),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Single emergency history card.
class _EmergencyHistoryCard extends StatelessWidget {
  final EmergencyModel emergency;

  const _EmergencyHistoryCard({required this.emergency});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: type + status badge
          Row(
            children: [
              Icon(
                _typeIcon(emergency.type),
                color: _statusColor(emergency.status),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  emergency.typeLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                      ),
                ),
              ),
              _StatusBadge(status: emergency.status),
            ],
          ),

          if (emergency.description != null &&
              emergency.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              emergency.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray600,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 10),

          // Date row
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: AppColors.gray500),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(emergency.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (emergency.address != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.location_on_rounded,
                    size: 14, color: AppColors.gray500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    emergency.address!,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          // Resolved info
          if (emergency.isResolved && emergency.resolvedAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Diselesaikan ${dateFormat.format(emergency.resolvedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'accident':
        return Icons.car_crash_rounded;
      case 'breakdown':
        return Icons.build_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'crime':
        return Icons.shield_rounded;
      default:
        return Icons.emergency_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.danger;
      case 'responding':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      default:
        return AppColors.gray500;
    }
  }
}

/// Status badge widget.
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        bgColor = AppColors.dangerLight;
        textColor = AppColors.danger;
        label = 'Aktif';
        break;
      case 'responding':
        bgColor = AppColors.warning.withOpacity(0.15);
        textColor = AppColors.warning;
        label = 'Ditangani';
        break;
      case 'resolved':
        bgColor = AppColors.success.withOpacity(0.15);
        textColor = AppColors.success;
        label = 'Selesai';
        break;
      default:
        bgColor = AppColors.gray100;
        textColor = AppColors.gray600;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
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
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Memuat riwayat...',
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📋', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Belum ada riwayat darurat',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Semoga tetap aman di jalan! 🙏',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
