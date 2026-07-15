import 'package:flutter/material.dart';

import 'package:kopdar_driver/config/theme.dart';
import 'package:kopdar_driver/core/utils/formatters.dart';
import 'package:kopdar_driver/features/pinjol/data/models/pinjol_model.dart';

class PayoffSimulator extends StatelessWidget {
  final int currentMonths;
  final PayoffSimulation? simulation;
  final ValueChanged<int> onMonthsChanged;
  final int minMonths;
  final int maxMonths;

  const PayoffSimulator({
    super.key,
    required this.currentMonths,
    this.simulation,
    required this.onMonthsChanged,
    this.minMonths = 1,
    this.maxMonths = 24,
  });

  @override
  Widget build(BuildContext context) {
    final result = simulation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧪 Simulasi Pelunasan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '$minMonths',
                style: const TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
              Expanded(
                child: Slider(
                  value: currentMonths.clamp(minMonths, maxMonths).toDouble(),
                  min: minMonths.toDouble(),
                  max: maxMonths.toDouble(),
                  divisions: maxMonths - minMonths,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.gray200,
                  onChanged: (value) => onMonthsChanged(value.round()),
                ),
              ),
              Text(
                '$maxMonths',
                style: const TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
            ],
          ),
          Center(
            child: Text(
              'Jika lunasi dalam $currentMonths bulan',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (result != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SimRow(
                    label: 'Total Pembayaran',
                    value: Formatters.currency(result.totalPayments.toInt()),
                  ),
                  const SizedBox(height: 8),
                  _SimRow(
                    label: 'Total Bunga',
                    value: Formatters.currency(result.totalInterest.toInt()),
                    valueColor: AppColors.danger,
                  ),
                  const SizedBox(height: 8),
                  _SimRow(
                    label: 'Bunga Terhemat',
                    value: Formatters.currency(result.interestSaved.toInt()),
                    valueColor: AppColors.success,
                  ),
                ],
              ),
            ),
            if (result.recommendation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.canAffordFromSavings
                      ? AppColors.success.withValues(alpha: 0.08)
                      : AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: result.canAffordFromSavings
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.warning.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.canAffordFromSavings ? '✅' : '💡',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.recommendation,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SimRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SimRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.gray900,
            ),
          ),
        ),
      ],
    );
  }
}
