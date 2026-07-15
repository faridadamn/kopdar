import 'package:flutter/material.dart';

import 'package:kopdar_driver/config/theme.dart';
import 'package:kopdar_driver/core/utils/formatters.dart';
import 'package:kopdar_driver/features/savings/data/models/saving_model.dart';
import 'package:kopdar_driver/features/savings/presentation/widgets/progress_ring.dart';

class SavingGoalCard extends StatelessWidget {
  final SavingModel goal;
  final VoidCallback? onTap;

  const SavingGoalCard({
    super.key,
    required this.goal,
    this.onTap,
  });

  Color get _statusColor {
    switch (goal.status) {
      case 'active':
        return AppColors.success;
      case 'paused':
        return AppColors.warning;
      case 'completed':
        return AppColors.primary;
      default:
        return AppColors.gray500;
    }
  }

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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    goal.goalIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.goalName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              goal.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _statusColor,
                              ),
                            ),
                          ),
                          if (goal.autoSave) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blueLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Auto',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                ProgressRing(
                  progress: goal.progress,
                  size: 52,
                  strokeWidth: 5,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.gray200,
                valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${Formatters.currency(goal.currentAmount.toInt())} / ${Formatters.currency(goal.targetAmount.toInt())}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${goal.progressPercent}% · ${goal.estimatedDays} hari lagi',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
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
