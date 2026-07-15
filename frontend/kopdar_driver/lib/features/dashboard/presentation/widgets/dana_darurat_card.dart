import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/formatters.dart';

/// Emergency fund progress card with progress bar.
class DanaDaruratCard extends StatelessWidget {
  final int currentAmount;
  final int targetAmount;
  final int dailyAmount;

  const DanaDaruratCard({
    super.key,
    required this.currentAmount,
    required this.targetAmount,
    required this.dailyAmount,
  });

  double get _progress =>
      targetAmount > 0 ? currentAmount / targetAmount : 0;

  int get _daysRemaining {
    final remaining = targetAmount - currentAmount;
    if (remaining <= 0 || dailyAmount <= 0) return 0;
    return (remaining / dailyAmount).ceil();
  }

  bool get _isOnTrack => _progress >= 0.3;

  @override
  Widget build(BuildContext context) {
    final progress = _progress.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Text('🏥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Dana Darurat',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (_isOnTrack)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'On Track',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Amount text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.currency(currentAmount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                'Target: ${Formatters.currency(targetAmount)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.gray200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),

          // Auto-save info
          Text(
            'Auto-tabung ${Formatters.currency(dailyAmount)}/hari → tercapai dalam $_daysRemaining hari',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gray600,
                ),
          ),
        ],
      ),
    );
  }
}
