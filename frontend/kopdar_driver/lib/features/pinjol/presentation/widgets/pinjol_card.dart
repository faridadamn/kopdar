import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/pinjol_model.dart';
import 'risk_badge.dart';

/// Card widget for a single loan in the pinjol list.
class PinjolCard extends StatelessWidget {
  final PinjolModel loan;
  final VoidCallback? onTap;

  const PinjolCard({
    super.key,
    required this.loan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // ── App name + risk badge ──
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text('💳', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.appName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bunga ${loan.interestRate.toStringAsFixed(1)}%/bulan',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                RiskBadge(riskLevel: loan.riskLevel, compact: true),
              ],
            ),
            const SizedBox(height: 14),

            // ── Stats row ──
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Sisa Pinjaman',
                    value: Formatters.currencyCompact(
                        loan.outstandingAmount.toInt()),
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.gray200,
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Cicilan/Bulan',
                    value: Formatters.currency(
                        loan.monthlyInstallment.toInt()),
                    alignment: CrossAxisAlignment.center,
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.gray200,
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Sisa Bulan',
                    value: '${loan.monthsRemaining} bln',
                    alignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment alignment;

  const _MiniStat({
    required this.label,
    required this.value,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.gray500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }
}
