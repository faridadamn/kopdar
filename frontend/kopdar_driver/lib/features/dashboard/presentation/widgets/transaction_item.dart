import 'package:flutter/material.dart';

import 'package:kopdar_driver/config/theme.dart';
import 'package:kopdar_driver/core/utils/formatters.dart';
import 'package:kopdar_driver/features/dashboard/data/models/transaction_item.dart'
    as model;

/// A single transaction row used in the recent-transactions list.
class TransactionItemTile extends StatelessWidget {
  final model.TransactionItem item;

  const TransactionItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final amountColor = item.isIncome ? AppColors.success : AppColors.danger;
    final sign = item.isIncome ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.isIncome ? AppColors.primaryBg : AppColors.dangerLight,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(item.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${Formatters.currency(item.amount.round())}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
          ),
        ],
      ),
    );
  }
}
