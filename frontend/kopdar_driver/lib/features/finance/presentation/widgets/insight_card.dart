import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../data/models/insight_model.dart';

/// Card displaying a financial insight with severity-colored background.
class InsightCard extends StatelessWidget {
  final InsightModel insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColor(insight.severity);
    final borderColor = _borderColor(insight.severity);
    final badgeColor = _badgeColor(insight.severity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + title + severity badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.gray700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  insight.severityLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _badgeTextColor(insight.severity),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _bgColor(String severity) {
    switch (severity) {
      case 'danger':
        return AppColors.dangerLight;
      case 'warning':
        return AppColors.accentLight;
      default:
        return AppColors.blueLight;
    }
  }

  Color _borderColor(String severity) {
    switch (severity) {
      case 'danger':
        return AppColors.danger.withOpacity(0.2);
      case 'warning':
        return AppColors.warning.withOpacity(0.2);
      default:
        return AppColors.info.withOpacity(0.2);
    }
  }

  Color _badgeColor(String severity) {
    switch (severity) {
      case 'danger':
        return AppColors.danger.withOpacity(0.15);
      case 'warning':
        return AppColors.warning.withOpacity(0.15);
      default:
        return AppColors.info.withOpacity(0.15);
    }
  }

  Color _badgeTextColor(String severity) {
    switch (severity) {
      case 'danger':
        return AppColors.danger;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }
}
