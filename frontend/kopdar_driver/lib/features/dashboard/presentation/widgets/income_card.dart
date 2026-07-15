import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/formatters.dart';

/// Green gradient card showing today's income summary.
class IncomeCard extends StatelessWidget {
  final int amount;
  final int orderCount;
  final double hours;
  final int avgPerOrder;
  final double changePercent;

  const IncomeCard({
    super.key,
    required this.amount,
    required this.orderCount,
    required this.hours,
    required this.avgPerOrder,
    required this.changePercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'Penghasilan Hari Ini',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 6),

          // Big amount
          Text(
            Formatters.currency(amount),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _StatChip(
                label: 'Order',
                value: '$orderCount',
              ),
              _divider,
              _StatChip(
                label: 'Jam',
                value: Formatters.hours(hours),
              ),
              _divider,
              _StatChip(
                label: 'Rata/order',
                value: Formatters.currency(avgPerOrder),
              ),
              _divider,
              _StatChip(
                label: 'Kemarin',
                value: Formatters.percentage(changePercent),
                valueColor:
                    changePercent >= 0 ? AppColors.success : AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget get _divider => Container(
        width: 1,
        height: 28,
        color: Colors.white24,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatChip({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valueColor ?? Colors.white,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white60,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
