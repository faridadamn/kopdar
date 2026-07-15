import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';

/// A stat card for the financial summary section.
class SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.bgColor = AppColors.primaryBg,
  });

  /// Factory for income card.
  factory SummaryCard.income({
    required double amount,
  }) {
    return SummaryCard(
      label: 'Penghasilan',
      value: amount,
      icon: Icons.trending_up_rounded,
      color: AppColors.success,
      bgColor: AppColors.primaryBg,
    );
  }

  /// Factory for expense card.
  factory SummaryCard.expense({
    required double amount,
  }) {
    return SummaryCard(
      label: 'Pengeluaran',
      value: amount,
      icon: Icons.trending_down_rounded,
      color: AppColors.danger,
      bgColor: AppColors.dangerLight,
    );
  }

  /// Factory for profit card.
  factory SummaryCard.profit({
    required double amount,
  }) {
    return SummaryCard(
      label: 'Keuntungan',
      value: amount,
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.blue,
      bgColor: AppColors.blueLight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gray500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(value.toInt()),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
