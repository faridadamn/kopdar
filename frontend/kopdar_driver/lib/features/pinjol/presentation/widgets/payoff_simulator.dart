import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/pinjol_model.dart';

/// Slider widget for payoff simulation.
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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

          // Slider
          Row(
            children: [
              Text(
                '$minMonths',
                style: TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
              Expanded(
                child: Slider(
                  value: currentMonths.toDouble(),
                  min: minMonths.toDouble(),
                  max: maxMonths.toDouble(),
                  divisions: maxMonths - minMonths,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.gray200,
                  onChanged: (value) =>
                      onMonthsChanged(value.round()),
                ),
              ),
              Text(
                '$maxMonths',
                style: TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
            ],
          ),

          // Label
          Center(
            child: Text(
              'Jika lunasi dalam $currentMonths bulan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Simulation results
          if (simulation != null) ...[
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
                    value: Formatters.currency(
                        simulation!.totalPayments.toInt()),
                  ),
                  const SizedBox(height: 8),
                  _SimRow(
                    label: 'Total Bunga',
                    value: Formatters.currency(
                        simulation!.totalInterest.toInt()),
                    valueColor: AppColors.danger,
                  ),
                  const SizedBox(height: 8),
                  _SimRow(
                    label: 'Bunga Terhemat',
                    value: Formatters.currency(
                        simulation!.interestSaved.toInt()),
                    valueColor: AppColors.success,
                  ),
                ],
              ),
            ),
            if (simulation!.recommendation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: simulation!.canAffordFromSavings
                      ? AppColors.success.withOpacity(0.08)
                      : AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: simulation!.canAffordFromSavings
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.warning.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      simulation!.canAffordFromSavings ? '✅' : '💡',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        simulation!.recommendation,
                        style: TextStyle(
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppColors.gray600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.gray900,
          ),
        ),
      ],
    );
  }
}
