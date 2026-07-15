import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../data/models/transaction_item.dart';
import 'transaction_item.dart';

/// List of recent transactions with a "Lihat Semua" link.
class RecentTransactions extends StatelessWidget {
  final List<TransactionItem> transactions;
  final VoidCallback? onViewAll;

  const RecentTransactions({
    super.key,
    required this.transactions,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaksi Terakhir',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'Lihat Semua →',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List
        if (transactions.isEmpty)
          _EmptyState()
        else
          ...transactions.map(
            (tx) => TransactionItemTile(item: tx),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            'Belum ada transaksi hari ini',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray500,
                ),
          ),
        ],
      ),
    );
  }
}
